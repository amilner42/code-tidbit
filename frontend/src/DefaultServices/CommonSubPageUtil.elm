module DefaultServices.CommonSubPageUtil exposing (..)


{-| All the common utilities needed in most sub-pages.
-}
type alias CommonSubPageUtil model shared msg =
    { justSetModel : model -> ( model, shared, Cmd.Cmd msg )
    , justUpdateModel : (model -> model) -> ( model, shared, Cmd.Cmd msg )
    , justSetShared : shared -> ( model, shared, Cmd.Cmd msg )
    , justUpdateShared : (shared -> shared) -> ( model, shared, Cmd.Cmd msg )
    , justProduceCmd : Cmd.Cmd msg -> ( model, shared, Cmd.Cmd msg )
    , doNothing : ( model, shared, Cmd.Cmd msg )
    , withCmd : Cmd.Cmd msg -> ( model, shared, Cmd.Cmd msg ) -> ( model, shared, Cmd.Cmd msg )
    , handleAll : List (( model, shared ) -> ( model, shared, Cmd msg )) -> ( model, shared, Cmd msg )
    }


{-| Creates the `CommonSubPageUtil` given the `model` and `shared`.
-}
commonSubPageUtil : model -> shared -> CommonSubPageUtil model shared msg
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
                            go (withCmd lastCmd (handleCurrent ( lastModel, lastShared ))) xs
            in
                go ( model, shared, Cmd.none )
    in
        { justSetModel = (\newModel -> ( newModel, shared, Cmd.none ))
        , justUpdateModel = (\modelUpdater -> ( modelUpdater model, shared, Cmd.none ))
        , justSetShared = (\newShared -> ( model, newShared, Cmd.none ))
        , justUpdateShared = (\sharedUpdater -> ( model, sharedUpdater shared, Cmd.none ))
        , justProduceCmd = (\newCmd -> ( model, shared, newCmd ))
        , doNothing = ( model, shared, Cmd.none )
        , withCmd = withCmd
        , handleAll = handleAll
        }
