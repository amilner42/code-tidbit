port module Main exposing (..)

import Components.Init exposing (init)
import Components.Messages exposing (Msg(..))
import Components.Model exposing (Model)
import Components.Update exposing (update)
import Components.View exposing (view)
import Navigation
import Subscriptions exposing (subscriptions)


{-| The entry point to the elm application. The navigation module allows us to
use the `urlUpdate` field so we can essentially subscribe to url changes.
-}
main : Program Never Model Msg
main =
    Navigation.program
        OnLocationChange
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }
