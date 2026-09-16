// CHO/FAT Metabolic - Garmin Connect IQ data field for real-time CHO/FAT
// oxidation estimation from heart rate.
// Copyright (C) 2026 Jordi Irazuzta
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

using Toybox.Application;
using Toybox.WatchUi;
using Toybox.Lang;

// Punt d'entrada de l'aplicació (Data Field).
// El manifest.xml apunta a aquesta classe amb entry="CHOFATDataFieldApp".
class CHOFATDataFieldApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state as Lang.Dictionary?) as Void {
    }

    // onStop() is called when your application is exiting
    function onStop(state as Lang.Dictionary?) as Void {
    }

    // Retorna la vista inicial: el nostre Data Field
    function getInitialView() as [ WatchUi.Views ] or [ WatchUi.Views, WatchUi.InputDelegates ] {
        return [ new CHOFATView() ];
    }
}
