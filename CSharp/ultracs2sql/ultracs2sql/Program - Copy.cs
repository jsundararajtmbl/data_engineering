using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Net;

namespace ultracs2sql
{
    class Program
    {
        static void Main(string[] args)
        {
            for (int i = 0; i < 79; i++)
            {
                Console.Write('-');
            }
            Console.WriteLine('-');
            Console.WriteLine("Started  : " + DateTime.Now.ToString());
            String hostName = Dns.GetHostName();
            Console.WriteLine("Hostname : " + hostName);

//          String[] pathList = new String[]
//          {
//              "\\\\prodsam\\SQL\\ultracs2sql\\" + hostName,
//              "\\\\testsam\\SQL\\ultracs2sql\\" + hostName,
//              "\\\\devsam\\SQL\\ultracs2sql\\" + hostName
//          };

            String[] pathList = new String[1];
            if (hostName == "NS01DB0V007") { pathList[0] = "\\\\prodsam\\SQL\\ultracs2sql\\" + hostName; }
            if (hostName == "NS01DB0V201") { pathList[0] = "\\\\testsam\\SQL\\ultracs2sql\\" + hostName; }
            if (hostName == "NS02DB0V204") { pathList[0] = "\\\\testsam\\SQL\\ultracs2sql\\" + hostName; }
            if (hostName == "NS02DB0V505") { pathList[0] = "\\\\devsam\\SQL\\ultracs2sql\\" + hostName; }
            if (pathList[0] is null) { pathList[0] = "\\\\devsam\\SQL\\ultracs2sql\\" + hostName; }

            foreach (var path in pathList)
            {
                folder src = new folder(path);
                folder wip = new folder(path + "\\wip");
                folder fin = new folder(path + "\\processed");
                folder log = new folder(path + "\\log");

                writeLog(log, "Pathname", path);

                foreach (var content in src.Contents)
                {
                    writeLog(log, "Found",
                        Convert.ToString(content.Extension.ToLower() +
                            " file " + content.Name));

                    try
                    {
                        String wipName = (wip.Path + "\\" + content.Name);
                        String finName = (fin.Path + "\\" + content.Name);
                        content.MoveTo(wipName);    // move to the WIP folder
                        System.IO.FileInfo wipContent = new System.IO.FileInfo(wipName);

                        switch (content.Extension.ToLower())
                        {
                            case ".txt":
                                break;
                            case ".sql":
                                runSQLscript(log, wipContent.FullName);   // TODO - should use the wipContent object
                                break;
                            default:
                                writeLog(log, "Error", "unhandled file type " + content.Extension);
                                break;
                        }
                        wipContent.MoveTo(finName);  // move from WIP to PROCESSED folder
                    }
                    catch (System.IO.IOException ioe)
                    {
                        writeLog(log, "IO Except", ioe.Message);
                        break;
                    }
                    catch (Exception e)
                    {
                        writeLog(log, "Exception", e.Message);
                        break;
                    }
                }
            }

            Console.WriteLine("Finished : " + DateTime.Now.ToString());
            if ( hostName == "LT-CBALDWIN" ) { Console.ReadLine();  }
        }

        public static void writeLog(folder log, String tag, String text)
        {
            String logFilename = log.Path + "\\" + DateTime.Now.ToString("yyyy-MM-dd") + ".txt";
            Console.WriteLine(text);
            using (System.IO.StreamWriter w = System.IO.File.AppendText(logFilename))
            {
                w.WriteLine(DateTime.Now.ToString("HH:mm:ss") + " " + tag.PadRight(9) + ": " + text);
            }
        }

        // run the file as a SQL script using the SQLCMD utility
        public static void runSQLscript(folder log, String file)
        {

            var proc = new Process
            {
                StartInfo = new ProcessStartInfo
                {
                    FileName = "SQLCMD.EXE",
                    Arguments = String.Format("-i {0}", file),
                    UseShellExecute = false,
                    RedirectStandardOutput = true,
                    CreateNoWindow = true
                }
            };

            writeLog(log, "Starting", "sqlcmd.exe -i " + file);
            proc.Start();

            while (!proc.StandardOutput.EndOfStream)
            {
                string line = proc.StandardOutput.ReadLine();
                writeLog(log, "Output", line);
            }
        }
    }

    public class folder
    {
        private String path;

        // default constructor - must exist but shouldn't get executed
        public folder()
        {
            Console.WriteLine("Error   : pathName is null");
        }

        // main constructor - pass in the base path name
        public folder(String pathName)
        {
            Path = pathName;
            Console.WriteLine("Pathname : " + Path);
            if (Info.Exists != true)
            {
                Info.Create();
            }
        }

        public String Path
        {
            get { return path; }
            set { path = value; }
        }

        // returns information about the folder - e.g. - does it exist?
        public System.IO.DirectoryInfo Info
        {
            get
            {
                System.IO.DirectoryInfo info = new System.IO.DirectoryInfo(path);
                return info;
            }
        }

        public List<System.IO.FileInfo> Contents
        {
            get
            {
                String[] files = System.IO.Directory.GetFiles(Path);
                Array.Sort(files, StringComparer.InvariantCulture);
                List<System.IO.FileInfo> contents = new List<System.IO.FileInfo>();
                foreach (var file in files)
                {
                    System.IO.FileInfo fi = new System.IO.FileInfo(file);
                    contents.Add(fi);
                }
                return contents;
            }
        }
    }
}
