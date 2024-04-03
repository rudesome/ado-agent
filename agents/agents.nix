{}:
{
  agent =
    { pkgs }:
      with pkgs;
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

        #patches = [ ./patches/dont-install-service.patch ];

        #postPatch = '' '';

        DOTNET_SYSTEM_GLOBALIZATION_INVARIANT = isNull glibcLocales;
        LOCALE_ARCHIVE = lib.optionalString (!DOTNET_SYSTEM_GLOBALIZATION_INVARIANT) "${glibcLocales}/lib/locale/locale-archive";

        postConfigure = ''
          # Generate src/Microsoft.VisualStudio.Services.Agent/BuildConstants.cs
          dotnet msbuild \
            -t:GenerateConstant \
            -p:ContinuousIntegrationBuild=true \
            -p:Deterministic=true \
            -p:BUILDCONFIG=Debug \
            -p:PackageRuntime="${dotnetCorePackages.systemToDotnetRid stdenv.hostPlatform.system}" \
            -p:AgentVersion="${version}" \
            src/dir.proj
        '';

        nativeBuildInputs = [
          autoPatchelfHook
          which
          git
        ];

        buildInputs = [
          stdenv.cc.cc.lib
          # TODO: dependencies in a nix way
          #"installdependencies.sh"
        ];

        dotnet-sdk = dotnetCorePackages.sdk_6_0;
        dotnet-runtime = dotnetCorePackages.runtime_6_0;

        dotnetFlags = [ "-p:PackageRuntime=${dotnetCorePackages.systemToDotnetRid stdenv.hostPlatform.system}" ];

        projectFile = [
          "src/Microsoft.VisualStudio.Services.Agent/Microsoft.VisualStudio.Services.Agent.csproj"
          "src/Agent.Listener/Agent.Listener.csproj"
          "src/Agent.Worker/Agent.Worker.csproj"
          "src/Agent.PluginHost/Agent.PluginHost.csproj"
          "src/Agent.Sdk/Agent.Sdk.csproj"
          "src/Agent.Plugins/Agent.Plugins.csproj"
        ];
        nugetDeps = ./deps.nix;

        doCheck = true;

        preCheck = ''
          mkdir -p _layout/externals
          ln -s ${nodejs_20} _layout/externals/node20
        '';

        postInstall = ''
          echo ".....postInstall"
        '';

        executables = [
          "Agent.Listener"
          "Agent.Worker"
          "Agent.PluginHost"
        ];

      };

}
