//   Program.cs
//
//  Author:
//       Allis Tauri <allista@gmail.com>
//
//  Copyright (c) 2016 Allis Tauri

﻿using AT_Utils;

namespace KSPAVCupdater
{
	class MainClass
	{
		public static void Main(string[] args)
		{
			KSP_AVC_Updater.UpdateFor(new AT_Utils.ModInfo(), 
			                          new AT_Utils.CCModInfo(),
			                          new AtHangar.ModInfo(),
			                          new ThrottleControlledAvionics.ModInfo(),
			                          new GroundConstruction.ModInfo());
		}
	}
}