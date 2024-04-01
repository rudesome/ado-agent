{}:
{
  agent =
    { lib
    , autoPatchelfHook
    , buildDotnetModule
    , dotnetCorePackages
    , fetchFromGitHub
    , git
    , glibcLocales
    , nodejs_20
    , stdenv
    , which
    }:
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

      #buildType = "Build";
      selfContainedBuild = false;

      projectFile = [
        "src/Microsoft.VisualStudio.Services.Agent/Microsoft.VisualStudio.Services.Agent.csproj"
        "src/Agent.Listener/Agent.Listener.csproj"
        "src/Agent.Worker/Agent.Worker.csproj"
        "src/Agent.PluginHost/Agent.PluginHost.csproj"
        "src/Agent.Sdk/Agent.Sdk.csproj"
        "src/Agent.Plugins/Agent.Plugins.csproj"
      ];

      nugetDeps = ./deps.nix;

      preConfigure = ''
        echo "....preConfigure"
        mkdir -p _layout/x64_linux
      '';

      prePatchPhase = ''
        ls -lsa
        rm -fr src/Test/NuGet.Config
        rm -fr src/Agent.Worker/NuGet.Config
        rm -fr src/Agent.Listener/NuGet.Config
        rm -fr src/Microsoft.VisualStudio.Services.Agent//NuGet.Config
      '';

      DOTNET_SYSTEM_GLOBALIZATION_INVARIANT = isNull glibcLocales;
      LOCALE_ARCHIVE = lib.optionalString (!DOTNET_SYSTEM_GLOBALIZATION_INVARIANT) "${glibcLocales}/lib/locale/locale-archive";

      postConfigure = ''
        echo "....postConfigre:"
        echo "....this is failing"
        dotnet msbuild \
          -p:AgentVersion=3.999.999 \
          -p:BUILDCONFIG=Debug \
          -p:Configuration=Release \
          -p:ContinuousIntegrationBuild=true \
          -p:Deterministic=true \
          -p:LayoutRoot=$out/_layout/x64-linux \
          -p:PackageType=pipelines-agent \
          -t:Build \
          -p:PackageRuntime="${dotnetCorePackages.systemToDotnetRid stdenv.hostPlatform.system}" \
          src/dir.proj
      '';

      buildPhase = ''
        echo ".....Hello from buildPhase"
      '';

      #patches = [ ./patches/dont-install-service.patch ];
      dotnet-sdk = dotnetCorePackages.sdk_6_0;
      dotnet-runtime = dotnetCorePackages.runtime_6_0;

      doCheck = false;

      buildInputs = [
        stdenv.cc.cc.lib
      ];

      executables = [
        "Agent.Listener"
        "Agent.Worker"
        "Agent.PluginHost"
        # dependencies in a nix way
        #"installdependencies.sh"
      ];

      preCheck = ''
        mkdir -p _layout/externals
        ln -s ${nodejs_20} _layout/externals/node20
      '';
      nativeBuildInputs = [
        autoPatchelfHook
        which
        git
      ];

    };

}
