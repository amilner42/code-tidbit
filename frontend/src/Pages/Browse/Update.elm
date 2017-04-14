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
update ({ doNothing, justSetShared, justUpdateModel, justSetModel, justProduceCmd, api } as common) msg model shared =
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
            common.handleAll
                [ -- Always update the model.
                  (\( model, shared ) -> ( { model | searchQuery = newSearchQuery }, shared, Cmd.none ))

                -- Only perform a search automatically if we're back to an empty search query.
                , (\( chainedModel, chainedShared ) ->
                    if String.isEmpty newSearchQuery then
                        performSearch True ( chainedModel, chainedShared )
                    else
                        ( chainedModel, chainedShared, Cmd.none )
                  )
                ]

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

        OnUpdateContentFilterAuthor newAuthorInput ->
            common.handleAll
                [ -- We always update the model.
                  (\( model, shared ) ->
                    ( { model | contentFilterAuthor = ( newAuthorInput, Nothing ) }
                    , shared
                    , Cmd.none
                    )
                  )

                -- We only need to perform a search if their was an author before and we just cleared it.
                , (\( chainedModel, chainedShared ) ->
                    if Util.isNotNothing <| Tuple.second model.contentFilterAuthor then
                        performSearch True ( chainedModel, chainedShared )
                    else
                        ( chainedModel, chainedShared, Cmd.none )
                  )

                -- We need to check if the new input is a valid email, unless the new input is an empty string.
                , (\( chainedModel, chainedShared ) ->
                    if String.isEmpty newAuthorInput then
                        ( chainedModel, chainedShared, Cmd.none )
                    else
                        ( chainedModel
                        , chainedShared
                        , api.get.userExistsWrapper newAuthorInput OnGetUserExistsFailure OnGetUserExistsSuccess
                        )
                  )
                ]

        OnGetUserExistsFailure apiError ->
            -- TODO Handle error.
            doNothing

        OnGetUserExistsSuccess (( forEmail, maybeID ) as newContentFilterAuthor) ->
            -- The user may have typed more before the request returned, in which case we don't care about the request.
            if forEmail == (Tuple.first model.contentFilterAuthor) then
                common.handleAll
                    [ -- We always update the model.
                      (\( model, shared ) ->
                        ( { model | contentFilterAuthor = newContentFilterAuthor }, shared, Cmd.none )
                      )

                    -- If a valid email has been past then we perform a search (with the user filter).
                    , (\( chainedModel, chainedShared ) ->
                        if Util.isNotNothing maybeID then
                            performSearch True ( chainedModel, chainedShared )
                        else
                            ( chainedModel, chainedShared, Cmd.none )
                      )
                    ]
            else
                doNothing


{-| Performs a search based on `initialSearch` and the current model, handles updating the model.
-}
performSearch : Bool -> ( Model, Shared ) -> ( Model, Shared, Cmd Msg )
performSearch initialSearch ( model, shared ) =
    let
        api =
            Api.api shared.flags.apiBaseUrl

        {- Get's the content with specific query params. -}
        getContent : List ( String, Maybe String ) -> Cmd Msg
        getContent queryParams =
            api.get.content queryParams OnGetContentFailure OnGetContentSuccess

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
            , ( "author", Tuple.second model.contentFilterAuthor )
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


{-| Checks if this is gauranteed to be the last content by seeing if less than the full page size is being returned from
the server (for all collections). But because this does not query the backend and just uses the pageSize, it could
happen that the backend returns the exact pageSize as the last content, but this function will assume there could be
more content.
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
