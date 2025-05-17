# VisualStudio role

This role installs Visual Studio and the required components

## Tasks

* Install visual studio from prepared offline zip archive

## How to build offline installer

This is antient magic and quite complicated one (thanks Microsoft!), so behold!

1. You need a specific version of VS:
   * Get the fixed version of bootstrapper: https://learn.microsoft.com/en-us/visualstudio/releases/2022/release-history#fixed-version-bootstrappers
2. Prepare a components list you want to install:
   * You can pick the individual components in the installer interface and then export it as vsconfig
   * Make sure you don't select any versioned component there - that will help you to migrate later to the new version
   * Recommend to use one SDK in the package and add the new/old ones via separated archives from TODO
   * And after UI generated the vsconfig for you - you need to refine it, otherwise next update time you will have tons of problems
   * Example of components.vsconfig:
      ```json
      {
        "version": "1.0",
        "components": [
          "Component.Microsoft.VisualStudio.LiveShare.2022",
          "Microsoft.Component.MSBuild",
          "Microsoft.Component.NetFX.Native",
          "Microsoft.VisualStudio.Component.AppInsights.Tools",
          "Microsoft.VisualStudio.Component.Debugger.JustInTime",
          "Microsoft.VisualStudio.Component.DiagnosticTools",
          "Microsoft.VisualStudio.Component.Graphics",
          "Microsoft.VisualStudio.Component.Graphics.Tools",
          "Microsoft.VisualStudio.Component.IntelliCode",
          "Microsoft.VisualStudio.Component.JavaScript.TypeScript",
          "Microsoft.VisualStudio.Component.NuGet",
          "Microsoft.VisualStudio.Component.Roslyn.Compiler",
          "Microsoft.VisualStudio.Component.Roslyn.LanguageServices",
          "Microsoft.VisualStudio.Component.SQL.CLR",
          "Microsoft.VisualStudio.Component.TextTemplating",
          "Microsoft.VisualStudio.Component.TypeScript.TSServer",
          "Microsoft.VisualStudio.Component.VC.ASAN",
          "Microsoft.VisualStudio.Component.VC.ATL",
          "Microsoft.VisualStudio.Component.VC.ATLMFC",
          "Microsoft.VisualStudio.Component.VC.CLI.Support",
          "Microsoft.VisualStudio.Component.VC.CMake.Project",
          "Microsoft.VisualStudio.Component.VC.CoreIde",
          "Microsoft.VisualStudio.Component.VC.DiagnosticTools",
          "Microsoft.VisualStudio.Component.VC.Llvm.ClangToolset",
          "Microsoft.VisualStudio.Component.VC.Redist.14.Latest",
          "Microsoft.VisualStudio.Component.VC.TestAdapterForBoostTest",
          "Microsoft.VisualStudio.Component.VC.TestAdapterForGoogleTest",
          "Microsoft.VisualStudio.Component.VC.Tools.x86.x64",
          "Microsoft.VisualStudio.Component.VSSDK",
          "Microsoft.VisualStudio.Component.Windows11SDK.26100",
          "Microsoft.VisualStudio.Workload.CoreEditor",
          "Microsoft.VisualStudio.Workload.NativeDesktop",
          "Microsoft.VisualStudio.Workload.Universal",
          "Microsoft.VisualStudio.Workload.VisualStudioExtension"
        ]
      }
      ```
3. Run the bootstrapper to prepare layout:
   ```
   C:\vs > .\vs_Professional_17.12.6.exe --layout "C:\vs\VS2022" --config "C:\vs\components.vsconfig" --lang en-US
   ```
4. Now pack everything in C:\vs directory as a zip file with name like `vs2022_17.12.6_offline-250516.201354.zip`
