module DefaultServices.LocalStorage exposing (saveModel, onLoadModel, loadModel)

import Components.Messages exposing (Msg(..))
import Components.Model exposing (Model, cacheEncoder, cacheDecoder)
import DefaultServices.Util as Util
import Ports


{-
   This module will not be needed soon, they are working on a cool localStorage
   cache system for elm, shoudl be released soon.

   This module requires a couple ports in the ports module and a script must be
   added to the index page.

   HTML (on index):

       <script>
         var modelKey = "model";
         var storedModel = localStorage.getItem(modelKey);
         var startingModel = storedModel ? JSON.parse(storedModel) : null;
         var elmApp = Elm.Main.fullscreen(startingModel);

         // Saves the model to local storage.
         elmApp.ports.saveModelToLocalStorage.subscribe(function(model) {
           localStorage.setItem(modelKey, JSON.stringify(model));
         });

         // Load the model from localStorage and send message to subscription over
         // port.
         elmApp.ports.loadModelFromLocalStorage.subscribe(function() {
           app.ports.onLoadModelFromLocalStorage.send(localStorage.getItem(modelKey))
         });
       </script>

     Ports:

     -- Saves the model to localstorage.
     port saveModelToLocalStorage : Encode.Value -> Cmd msg

     -- Loads the model from local storage.
     port loadModelFromLocalStorage : () -> Cmd msg

     -- Upon loading the model from local storage.
     port onLoadModelFromLocalStorage : (String -> msg) -> Sub msg
-}


{-| Saves the model to localStorage using the port.
-}
saveModel : Model -> Cmd msg
saveModel model =
    Ports.saveModelToLocalStorage <| cacheEncoder <| model


{-| Will be used for the port subscription.
-}
onLoadModel : String -> Msg
onLoadModel modelAsStringFromStorage =
    case (Util.fromJsonString cacheDecoder modelAsStringFromStorage) of
        Ok model ->
            OnLoadModelFromLocalStorageSuccess model

        Err error ->
            OnLoadModelFromLocalStorageFailure error


{-| Triggers the model to be loaded from local storage
-}
loadModel : () -> Cmd Msg
loadModel =
    Ports.loadModelFromLocalStorage
