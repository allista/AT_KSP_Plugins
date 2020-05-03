//   Program.cs
//
//  Author:
//       Allis Tauri <allista@gmail.com>
//
//  Copyright (c) 2016 Allis Tauri

using AT_Utils;

namespace KSPAVCupdater
{
    internal static class MainClass
    {
        public static void Main(string[] args)
        {
            KSP_AVC_Updater.UpdateFor(new ModInfo(),
                new CCModInfo(),
                new AtHangar.ModInfo(),
                new ThrottleControlledAvionics.ModInfo(),
                new GroundConstruction.ModInfo(),
                new CargoAccelerators.ModInfo(),
                new AutoLoadGame.ModInfo());
        }
    }
}
