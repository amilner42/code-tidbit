module Pages.Browse.Update exposing (..)

import Api
import DefaultServices.CommonSubPageUtil exposing (CommonSubPageUtil)
import DefaultServices.Util as Util
import Models.Content as Content
import Models.Route as Route
import Pages.Browse.Messages exposing (..)
import Pages.Browse.Model exposing (..)
import Pages.Model exposing (Shared)
import Ports


{-| `Browse` update.
-}
update : CommonSubPageUtil Model Shared Msg -> Msg -> Model -> Shared -> ( Model, Shared, Cmd Msg )
update ({ doNothing, justSetShared, justUpdateModel, justSetModel, justProduceCmd } as common) msg model shared =
    case msg of
        NoOp ->
            doNothing

        GoTo route ->
            justProduceCmd <| Route.navigateTo route

        OnRouteHit route ->
            case route of
                Route.BrowsePage ->
                    common.withCmd
                        (Cmd.batch
                            [ (Util.domFocus (always NoOp) "search-bar")
                            , if model.showAdvancedSearchOptions then
                                Ports.expandSearchAdvancedOptions True
                              else
                                Cmd.none
                            ]
                        )
                        (performSearch True ( model, shared ))

                _ ->
                    doNothing

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
            performSearch False ( model, shared )

        OnUpdateSearch newSearchQuery ->
            if String.isEmpty newSearchQuery then
                common.handleAll
                    [ (\( model, shared ) ->
                        ( { model | searchQuery = "" }
                        , shared
                        , Cmd.none
                        )
                      )
                    , performSearch True
                    ]
            else
                justSetModel { model | searchQuery = newSearchQuery }

        Search ->
            performSearch True ( model, shared )

        ToggleAdvancedOptions ->
            ( { model | showAdvancedSearchOptions = not model.showAdvancedSearchOptions }
            , shared
            , Ports.expandSearchAdvancedOptions <| not model.showAdvancedSearchOptions
            )

        ToggleContentFilterSnipbits ->
            let
                updateFilterSnipbits : ( Model, Shared ) -> ( Model, Shared, Cmd Msg )
                updateFilterSnipbits ( model, shared ) =
                    ( { model | contentFilterSnipbits = not model.contentFilterSnipbits }
                    , shared
                    , Cmd.none
                    )
            in
                if (not model.contentFilterBigbits) && (not model.contentFilterStories) then
                    doNothing
                else
                    common.handleAll
                        [ updateFilterSnipbits
                        , performSearch True
                        ]

        ToggleContentFilterBigbits ->
            let
                updateFilterBigbits : ( Model, Shared ) -> ( Model, Shared, Cmd Msg )
                updateFilterBigbits ( model, shared ) =
                    ( { model | contentFilterBigbits = not model.contentFilterBigbits }
                    , shared
                    , Cmd.none
                    )
            in
                if (not model.contentFilterSnipbits) && (not model.contentFilterStories) then
                    doNothing
                else
                    common.handleAll
                        [ updateFilterBigbits
                        , performSearch True
                        ]

        ToggleContentFilterStories ->
            let
                updateFilterStories : ( Model, Shared ) -> ( Model, Shared, Cmd Msg )
                updateFilterStories ( model, shared ) =
                    ( { model | contentFilterStories = not model.contentFilterStories }
                    , shared
                    , Cmd.none
                    )
            in
                if (not model.contentFilterSnipbits) && (not model.contentFilterBigbits) then
                    doNothing
                else
                    common.handleAll
                        [ updateFilterStories
                        , performSearch True
                        ]

        SetIncludeEmptyStories includeEmptyStories ->
            let
                updateIncludeEmptyStories : ( Model, Shared ) -> ( Model, Shared, Cmd Msg )
                updateIncludeEmptyStories ( model, shared ) =
                    ( { model | contentFilterIncludeEmptyStories = includeEmptyStories }
                    , shared
                    , Cmd.none
                    )
            in
                common.handleAll
                    [ updateIncludeEmptyStories
                    , performSearch True
                    ]

        SelectLanguage maybeLanguage ->
            common.handleAll
                [ (\( model, shared ) -> ( { model | contentFilterLanguage = maybeLanguage }, shared, Cmd.none ))
                , performSearch True
                ]


{-| Get's the results for a specific search query.

Updates the model accordingly dependent on whether it is the `initialSearch` and whether the `model.searchQuery` is
empty.
-}
performSearch : Bool -> ( Model, Shared ) -> ( Model, Shared, Cmd Msg )
performSearch initialSearch ( model, shared ) =
    let
        toJSBool bool =
            if bool then
                "true"
            else
                "false"

        commonQueryParams =
            [ ( "includeSnipbits", Just <| toJSBool model.contentFilterSnipbits )
            , ( "includeBigbits", Just <| toJSBool model.contentFilterBigbits )
            , ( "includeStories", Just <| toJSBool model.contentFilterStories )
            , ( "includeEmptyStories", Just <| toJSBool model.contentFilterIncludeEmptyStories )
            , ( "restrictLanguage", Maybe.map toString model.contentFilterLanguage )
            ]
    in
        if Util.isBlankString model.searchQuery then
            ( if initialSearch then
                { model
                    | pageNumber = 1
                    , showNewContentMessage = True
                    , content = Nothing
                    , noMoreContent = False
                }
              else
                model
            , shared
            , getContent <|
                commonQueryParams
                    ++ [ ( "sortByLastModified", Just "true" )
                       , ( "pageNumber"
                         , Just <|
                            if initialSearch then
                                "1"
                            else
                                toString model.pageNumber
                         )
                       ]
            )
        else
            ( if initialSearch then
                { model
                    | pageNumber = 1
                    , showNewContentMessage = False
                    , content = Nothing
                    , noMoreContent = False
                }
              else
                model
            , shared
            , getContent <|
                commonQueryParams
                    ++ [ ( "searchQuery", Util.justNonBlankString model.searchQuery )
                       , ( "sortByTextScore", Just "true" )
                       , ( "pageNumber"
                         , Just <|
                            if initialSearch then
                                "1"
                            else
                                toString model.pageNumber
                         )
                       ]
            )


{-| Get's the content with specific query params.
-}
getContent : List ( String, Maybe String ) -> Cmd Msg
getContent queryParams =
    Api.getContent queryParams OnGetContentFailure OnGetContentSuccess


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
