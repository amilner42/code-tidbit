module Subscriptions exposing (subscriptions)

import Components.Messages exposing (Msg)
import Components.Model exposing (Model)
import DefaultServices.LocalStorage as LocalStorage
import Ports


{-| All the application subscriptions.
-}
subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch [ Ports.onLoadModelFromLocalStorage LocalStorage.onLoadModel ]
