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
