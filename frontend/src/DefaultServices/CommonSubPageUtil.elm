module DefaultServices.CommonSubPageUtil exposing (..)

import Api
import Flags exposing (Flags)
import Pages.Model exposing (Shared)
import Models.ApiError as ApiError


{-| All the common utilities for manipulating `(Model, Shared)` -> `(Model, Shared, Cmd Msg)`.

NOTE: It's a type wrapper around an alias (instead of just a type alias) to allow for recursion:
  - https://github.com/elm-lang/elm-compiler/blob/0.18.0/hints/recursive-alias.md
-}
type CommonSubPageUtil model shared msg
    = Common
        { justSetModel : model -> ( model, shared, Cmd.Cmd msg )
        , justUpdateModel : (model -> model) -> ( model, shared, Cmd.Cmd msg )
        , justSetShared : shared -> ( model, shared, Cmd.Cmd msg )
        , justUpdateShared : (shared -> shared) -> ( model, shared, Cmd.Cmd msg )
        , justProduceCmd : Cmd.Cmd msg -> ( model, shared, Cmd.Cmd msg )
        , doNothing : ( model, shared, Cmd.Cmd msg )
        , withCmd : Cmd.Cmd msg -> ( model, shared, Cmd.Cmd msg ) -> ( model, shared, Cmd.Cmd msg )
        , handleAll :
            List (CommonSubPageUtil model shared msg -> ( model, shared ) -> ( model, shared, Cmd msg ))
            -> ( model, shared, Cmd msg )
        , api : Api.API msg
        , justSetModalError : ApiError.ApiError -> ( model, shared, Cmd.Cmd msg )
        }


{-| Creates the `CommonSubPageUtil` given the `model` and `shared`.

As you can see, this declares `Shared` instead of leaving it as a type parameter, this allows us to define a few extra
helpful functions for sub-pages
-}
commonSubPageUtil : model -> Shared -> CommonSubPageUtil model Shared msg
commonSubPageUtil model shared =
    let
        withCmd withCmd ( newModel, newShared, newCmd ) =
            ( newModel, newShared, Cmd.batch [ newCmd, withCmd ] )

        handleAll =
            let
                go ( lastModel, lastShared, lastCmd ) listOfThingsToHandle =
                    case listOfThingsToHandle of
                        [] ->
                            ( lastModel, lastShared, lastCmd )

                        handleCurrent :: xs ->
                            go
                                (withCmd lastCmd <|
                                    handleCurrent (commonSubPageUtil lastModel lastShared) ( lastModel, lastShared )
                                )
                                xs
            in
                go ( model, shared, Cmd.none )
    in
        Common
            { justSetModel = (\newModel -> ( newModel, shared, Cmd.none ))
            , justUpdateModel = (\modelUpdater -> ( modelUpdater model, shared, Cmd.none ))
            , justSetShared = (\newShared -> ( model, newShared, Cmd.none ))
            , justUpdateShared = (\sharedUpdater -> ( model, sharedUpdater shared, Cmd.none ))
            , justProduceCmd = (\newCmd -> ( model, shared, newCmd ))
            , doNothing = ( model, shared, Cmd.none )
            , withCmd = withCmd
            , handleAll = handleAll
            , api = Api.api shared.flags.apiBaseUrl
            , justSetModalError = (\apiError -> ( model, { shared | apiModalError = Just apiError }, Cmd.none ))
            }
