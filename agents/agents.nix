{}:
{
  agent = { lib, buildDotnetModule, fetchFromGitHub, which, git }:
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

      postConfigure = ''
        echo "....postConfigre:"
        echo "....this is failing"
        dotnet msbuild \
          -t:Build \
          -p:PackageRuntime=linux-x64 \
          -p:PackageType=pipelines-agent \
          -p:BUILDCONFIG=Release \
          -p:AgentVersion=3.999.999 \
          -p:LayoutRoot=$out/_layout/x64-linux \
          -p:CodeAnalysis=true
      '';

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
