module Pages.Browse.Update exposing (..)

import Api
import DefaultServices.CommonSubPageUtil exposing (CommonSubPageUtil)
import Pages.Browse.Messages exposing (..)
import Pages.Browse.Model exposing (..)
import Pages.Model exposing (Shared)


{-| `Browse` update.
-}
update : CommonSubPageUtil Model Shared Msg -> Msg -> Model -> Shared -> ( Model, Shared, Cmd Msg )
update { doNothing, justSetShared, justUpdateModel, justSetModel, justProduceCmd } msg model shared =
    case msg of
        NoOp ->
            doNothing

        OnRouteHit route ->
            case model.content of
                Nothing ->
                    justProduceCmd <| getNewestContent model.pageNumber

                Just _ ->
                    doNothing

        OnGetContentSuccess content ->
            case model.content of
                Nothing ->
                    justSetModel
                        { model
                            | content = Just content
                            , pageNumber = 2
                        }

                Just currentContent ->
                    justSetModel
                        { model
                            | content = Just <| currentContent ++ content
                            , pageNumber = model.pageNumber + 1
                        }

        OnGetContentFailure apiError ->
            -- TODO handle error.
            doNothing


{-| Get's the newest content.
-}
getNewestContent : Int -> Cmd Msg
getNewestContent pageNumber =
    Api.getContent
        [ ( "sortByLastModified", Just "true" )
        , ( "pageNumber", Just <| toString pageNumber )
        ]
        OnGetContentFailure
        OnGetContentSuccess
