module Subscriptions exposing (subscriptions)

import Autocomplete as AC
import Components.Home.Messages exposing (Msg(SnipbitUpdateACState))
import Components.Messages exposing (Msg(HomeMessage, CodeEditorUpdate, CodeEditorSelectionUpdate, KeyboardExtraMessage))
import Components.Model exposing (Model)
import DefaultServices.LocalStorage as LocalStorage
import Keyboard.Extra
import Ports


{-| All the application subscriptions.
-}
subscriptions : Model -> Sub Components.Messages.Msg
subscriptions model =
    Sub.batch
        [ Ports.onLoadModelFromLocalStorage LocalStorage.onLoadModel
        , Ports.onCodeEditorUpdate CodeEditorUpdate
        , Ports.onCodeEditorSelectionUpdate CodeEditorSelectionUpdate
        , Sub.map (HomeMessage << SnipbitUpdateACState) AC.subscription
        , Sub.map KeyboardExtraMessage Keyboard.Extra.subscriptions
        ]
