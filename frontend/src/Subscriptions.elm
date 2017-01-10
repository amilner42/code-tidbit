module Subscriptions exposing (subscriptions)

import Autocomplete as AC
import Components.Home.Messages exposing (Msg(BasicTidbitUpdateACState))
import Components.Messages exposing (Msg(HomeMessage))
import Components.Model exposing (Model)
import DefaultServices.LocalStorage as LocalStorage
import Ports


{-| All the application subscriptions.
-}
subscriptions : Model -> Sub Components.Messages.Msg
subscriptions model =
    Sub.batch
        [ Ports.onLoadModelFromLocalStorage LocalStorage.onLoadModel
        , Sub.map (HomeMessage << BasicTidbitUpdateACState) AC.subscription
        ]
