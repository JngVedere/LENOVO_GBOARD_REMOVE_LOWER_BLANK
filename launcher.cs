// Lenovo Gboard Blank Patcher.exe: unpacks the embedded app.zip (built by build.ps1) to
// %LOCALAPPDATA%\gboardblank\app and starts gui.ps1 there without a console window.
using System;
using System.Diagnostics;
using System.IO;
using System.IO.Compression;
using System.Reflection;

static class Launcher
{
    static void Main()
    {
        string app = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), @"gboardblank\app");
        try
        {
            if (Directory.Exists(app)) Directory.Delete(app, true);
            using (var zip = new ZipArchive(Assembly.GetExecutingAssembly().GetManifestResourceStream("app.zip")))
                zip.ExtractToDirectory(app);
        }
        catch (IOException) { } // another running copy holds the files: reuse them
        Process.Start(new ProcessStartInfo("powershell", "-NoProfile -ExecutionPolicy Bypass -File \"" + Path.Combine(app, "gui.ps1") + "\"")
            { UseShellExecute = false, CreateNoWindow = true });
    }
}
