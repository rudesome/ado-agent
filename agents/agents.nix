{ nodeRuntimes ? [ "node20" ] }:
{
  agent =
    { pkgs }:
      with pkgs;

      assert builtins.all (x: builtins.elem x [ "node20" ]) nodeRuntimes;

      buildDotnetModule rec {
        pname = "ado-agent";
        version = "3.236.1";

        src = fetchFromGitHub {
          owner = "microsoft";
          repo = "azure-pipelines-agent";
          rev = "v${version}";
          hash = "sha256-9t44+qowoZeZSe38gvw2pLuDsUMFpgdajCg23h+OiRM=";
          leaveDotGit = true;
          postFetch = ''
            git -C $out rev-parse --short HEAD > $out/.git-revision
            rm -rf $out/.git
          '';
        };

        unpackPhase = ''
          cp -r $src $TMPDIR/src
          chmod -R +w $TMPDIR/src
          cd $TMPDIR/src
          (
          export PATH=${buildPackages.git}/bin:$PATH
          git init
          git config user.email "root@localhost"
          git config user.name "root"
          git add .
          git commit -m "Initial commit"
          git checkout -b v${version}
          )
          mkdir -p $TMPDIR/bin
          cat > $TMPDIR/bin/git <<EOF
          #!${runtimeShell}
          if [ \$# -eq 1 ] && [ "\$1" = "rev-parse" ]; then
          echo $(cat $TMPDIR/src/.git-revision)
          exit 0
          fi
          exec ${buildPackages.git}/bin/git "\$@"
          EOF
          chmod +x $TMPDIR/bin/git
          export PATH=$TMPDIR/bin:$PATH
        '';

        patches = [
          ./patches/dont-install-service.patch
          ./patches/host-context-dirs.patch
          ./patches/set-layout-path.patch
          ./patches/remove-windows-check.patch
          ./patches/remove-processUtil.patch
          ./patches/remove-buildXL.patch
        ];


        DOTNET_SYSTEM_GLOBALIZATION_INVARIANT = isNull glibcLocales;
        LOCALE_ARCHIVE = lib.optionalString (!DOTNET_SYSTEM_GLOBALIZATION_INVARIANT) "${glibcLocales}/lib/locale/locale-archive";

        preConfigure = ''
          echo "preconfig"
          mkdir -p _layout/bin
          # Generate src/Microsoft.VisualStudio.Services.Agent/BuildConstants.cs
          dotnet msbuild \
            -t:GenerateConstant \
            -p:ContinuousIntegrationBuild=true \
            -p:Deterministic=true \
            -p:PackageRuntime="${dotnetCorePackages.systemToDotnetRid stdenv.hostPlatform.system}" \
            -p:AgentVersion="${version}" \
            src/dir.proj
        '';

        nativeBuildInputs = [
          autoPatchelfHook
          which
          git
          dotnetPackages.Nuget
          makeWrapper
          wrapGAppsHook
          gobject-introspection
        ];


        buildInputs = [
          stdenv.cc.cc.lib
          # https://github.com/microsoft/azure-pipelines-agent/blob/a3d91272cbe4a61d96084d9d94e4750b743f0a49/src/Misc/layoutbin/installdependencies.sh#L101
        ];

        dotnet-sdk = dotnetCorePackages.sdk_6_0;
        dotnet-runtime = dotnetCorePackages.runtime_6_0;

        dotnetFlags = [
          "-p:PackageRuntime=${dotnetCorePackages.systemToDotnetRid stdenv.hostPlatform.system}"
        ];

        projectFile = [
          "src/Agent.Sdk/Agent.Sdk.csproj"
          "src/Agent.Listener/Agent.Listener.csproj"
          "src/Microsoft.VisualStudio.Services.Agent/Microsoft.VisualStudio.Services.Agent.csproj"
          "src/Agent.Worker/Agent.Worker.csproj"
          "src/Agent.PluginHost/Agent.PluginHost.csproj"
          "src/Agent.Plugins/Agent.Plugins.csproj"
        ];
        nugetDeps = ./deps.nix;

        #doCheck = true;

        preCheck = ''
          mkdir -p _layout/externals
          ln -s ${nodejs_20} _layout/externals/node20_1
        '';

        postInstall = ''
          echo ".....postInstall"
          mkdir -p $out/bin
          ls -lsa
          ls -lsa src/Misc/layoutroot

          install -m755 src/Misc/layoutbin/runsvc.sh                $out/lib/${pname}
          install -m755 src/Misc/layoutbin/AgentService.js          $out/lib/${pname}
          install -m755 src/Misc/layoutroot/run.sh                  $out/lib/${pname}
          #install -m755 src/Misc/layoutroot/run-helper.sh.template  $out/lib/agent/run-helper.sh
          install -m755 src/Misc/layoutroot/config.sh               $out/lib/${pname}
          install -m755 src/Misc/layoutroot/env.sh                  $out/lib/${pname}

        '';

        executables = [
          "config.sh"
          "Agent.Listener"
          "Agent.Worker"
          "Agent.PluginHost"
          "env.sh"
          "run.sh"
        ];

      };

}
