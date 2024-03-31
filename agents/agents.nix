{}:
{
  agent = { lib, buildDotnetModule, fetchFromGitHub, which, git, stdenv, dotnetCorePackages }:
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

      postConfigure = ''
        echo "....postConfigre:"
        echo "....this is failing"
        echo "${dotnetCorePackages.systemToDotnetRid stdenv.hostPlatform.system}"

        ls -lsa
        dotnet msbuild \
          -p:AgentVersion=3.999.999 \
          -p:BUILDCONFIG=Release \
          -p:Configuration=Release
          -p:ContinuousIntegrationBuild=true \
          -p:Deterministic=true \
          -p:LayoutRoot=$out/_layout/x64-linux \
          -p:PackageRuntime="${dotnetCorePackages.systemToDotnetRid stdenv.hostPlatform.system}" \
          -p:RuntimeIdentifier="${dotnetCorePackages.systemToDotnetRid stdenv.hostPlatform.system}" \
          -p:PackageType=pipelines-agent \
          -t:Build
      '';

      dotnet-sdk = dotnetCorePackages.sdk_6_0;
      dotnet-runtime = dotnetCorePackages.runtime_6_0;

      doCheck = true;
      preCheck = ''
        echo "....Ello from precheck"
        mkdir -p _layout/x64-linux
      '';

      nativeBuildInputs = [
        which
        git
      ];

    };

}
