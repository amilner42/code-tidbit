module Pages.Browse.Update exposing (..)

import Api
import Models.Content as Content
import DefaultServices.CommonSubPageUtil exposing (CommonSubPageUtil)
import Models.Route as Route
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

        GoTo route ->
            justProduceCmd <| Route.navigateTo route

        OnRouteHit route ->
            ( { model | content = Nothing }
            , shared
            , getNewestContent 1
            )

        OnGetContentSuccess content ->
            case model.content of
                Nothing ->
                    justSetModel
                        { model
                            | content = Just content
                            , pageNumber = 2
                            , noMoreContent = isNoMoreContent 10 content
                        }

                Just currentContent ->
                    justSetModel
                        { model
                            | content = Just <| currentContent ++ content
                            , pageNumber = model.pageNumber + 1
                            , noMoreContent = isNoMoreContent 10 content
                        }

        OnGetContentFailure apiError ->
            -- TODO handle error.
            doNothing

        LoadMoreContent ->
            justProduceCmd <| getNewestContent model.pageNumber


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


{-| Checks if this is gauranteed to be the last content by seeing if less than the full page size is being returned from
the server (for all collections).
-}
isNoMoreContent : Int -> List Content.Content -> Bool
isNoMoreContent pageSize content =
    let
        go ( snipbits, bigbits, stories ) remainingContent =
            case remainingContent of
                [] ->
                    (snipbits < pageSize) && (bigbits < pageSize) && (stories < pageSize)

                h :: xs ->
                    case h of
                        Content.Snipbit _ ->
                            go ( snipbits + 1, bigbits, stories ) xs

                        Content.Bigbit _ ->
                            go ( snipbits, bigbits + 1, stories ) xs

                        Content.Story _ ->
                            go ( snipbits, bigbits, stories + 1 ) xs
    in
        go ( 0, 0, 0 ) content
