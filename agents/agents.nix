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

        #unpackPhase = ''
        #cp -r $src $TMPDIR/src
        #chmod -R +w $TMPDIR/src
        #cd $TMPDIR/src
        #(
        #export PATH=${buildPackages.git}/bin:$PATH
        #git init
        #git config user.email "root@localhost"
        #git config user.name "root"
        #git add .
        #git commit -m "Initial commit"
        #git checkout -b v${version}
        #)
        #mkdir -p $TMPDIR/bin
        #cat > $TMPDIR/bin/git <<EOF
        ##!${runtimeShell}
        #if [ \$# -eq 1 ] && [ "\$1" = "rev-parse" ]; then
        #echo $(cat $TMPDIR/src/.git-revision)
        #exit 0
        #fi
        #exec ${buildPackages.git}/bin/git "\$@"
        #EOF
        #chmod +x $TMPDIR/bin/git
        #export PATH=$TMPDIR/bin:$PATH
        #'';

        patches = [
          ./patches/dont-install-service.patch
          ./patches/host-context-dirs.patch
          ./patches/set-layout-path.patch
          ./patches/remove-windows-check.patch
          ./patches/remove-processUtil.patch
          ./patches/remove-buildXL.patch
        ];


        postPatch = ''
          # not using System.Management?
          #substituteInPlace src/Agent.Sdk/Util/ProcessUtil.cs \
          #--replace 'using System.Management;' \
          #' '
        '';

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

        preBuild = ''
          ls -lsa _layout
          ls -lsa _layout/bin
        '';
        #preBuild = ''
        # override csproj with own config / package references
        #echo "......PREBUILD"
        #cat << 'EOF' > /build/src/src/Agent.Sdk/Agent.Sdk.csproj
        #<Project Sdk="Microsoft.NET.Sdk">
        #<Import Project="..\Common.props" />

        #<PropertyGroup>
        #<OutputType>Library</OutputType>
        #<SuppressTfmSupportBuildWarnings>true</SuppressTfmSupportBuildWarnings>
        #</PropertyGroup>

        #<ItemGroup>
        #<PackageReference Include="Microsoft.Windows.Compatibility" Version="6.0.0" />
        #<PackageReference Include="Microsoft.CodeAnalysis.FxCopAnalyzers" Version="2.9.8" Condition="$(CodeAnalysis)=='true'" />
        #<PackageReference Include="Microsoft.Win32.Registry" Version="5.0.0" />
        #<PackageReference Include="System.IO.FileSystem.AccessControl" Version="6.0.0-preview.5.21301.5" />
        #<PackageReference Include="System.Management" Version="4.7.0" />
        #<PackageReference Include="System.ServiceProcess.ServiceController" Version="6.0.1" />
        #<PackageReference Include="System.Security.Principal.Windows" Version="6.0.0-preview.5.21301.5" />
        #<PackageReference Include="System.Text.Encoding.CodePages" Version="4.4.0" />
        #<PackageReference Include="vss-api-netcore" Version="$(VssApiVersion)" />
        #</ItemGroup>
        #</Project>
        #EOF
        ##cat /build/src/src/Agent.Sdk/Agent.Sdk.csproj
        #'';

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

        dotnetBuildFlags = [
          #"-t:Layout"
          "-p:PackageType=agent"
          #"-p:LayoutRoot=_layout/linux-x64"
          "-p:BUILDCONFIG=Release"
          "-p:PackageRuntime=linux-x64"
          #"-p:PackageRuntime=${dotnetCorePackages.systemToDotnetRid stdenv.hostPlatform.system}"
          "-p:AgentVersion=${version}"
          #"-p:LayoutRoot=_layout/linux-x64"
          "-p:CodeAnalysis=true"
        ];

        #dotnetFlags = [
        #"-p:PackageRuntime=${dotnetCorePackages.systemToDotnetRid stdenv.hostPlatform.system}"
        #];

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
        '';

        #executables = [
        #"Agent.Listener"
        #"Agent.Worker"
        #"Agent.PluginHost"
        #];

      };

}
