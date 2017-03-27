module Subscriptions exposing (subscriptions)

import Autocomplete as AC
import DefaultServices.LocalStorage as LocalStorage
import Keyboard.Extra
import Pages.CreateSnipbit.Messages exposing (Msg(OnUpdateACState))
import Pages.Messages exposing (..)
import Pages.Model exposing (Model)
import Ports


{-| All the application subscriptions.
-}
subscriptions : Model -> Sub Pages.Messages.Msg
subscriptions model =
    Sub.batch
        [ Ports.onLoadModelFromLocalStorage LocalStorage.onLoadModel
        , Ports.onCodeEditorUpdate CodeEditorUpdate
        , Ports.onCodeEditorSelectionUpdate CodeEditorSelectionUpdate
        , Sub.map (CreateSnipbitMessage << OnUpdateACState) AC.subscription
        , Sub.map KeyboardExtraMessage Keyboard.Extra.subscriptions
        ]
