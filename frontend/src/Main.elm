port module Main exposing (..)

import Navigation
import Pages.Init exposing (init)
import Pages.Messages exposing (Msg(..))
import Pages.Model exposing (Model)
import Pages.Update exposing (update)
import Pages.View exposing (view)
import Subscriptions exposing (subscriptions)


{-| The entry point to the elm application. The navigation module allows us to use the `urlUpdate` field so we can
essentially subscribe to url changes.
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
