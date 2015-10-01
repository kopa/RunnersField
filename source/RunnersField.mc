using Toybox.Application as App;

//! @author Konrad Paumann
class RunnersField extends App.AppBase {

    function onStart() {
    }

    function onStop() {
    }

    function getInitialView() {
        return [ new RunnersView() ];
    }

}