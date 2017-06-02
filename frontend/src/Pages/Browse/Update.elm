module Pages.Browse.Update exposing (..)

import Api
import DefaultServices.CommonSubPageUtil exposing (CommonSubPageUtil(..))
import DefaultServices.Util as Util
import Models.Content as Content
import Models.Route as Route
import Pages.Browse.Messages exposing (..)
import Pages.Browse.Model exposing (..)
import Pages.Model exposing (Shared)
import Ports
import ProjectTypeAliases exposing (..)


{-| `Browse` update.
-}
update : CommonSubPageUtil Model Shared Msg -> Msg -> Model -> Shared -> ( Model, Shared, Cmd Msg )
update ((Common common) as commonUtil) msg model shared =
    case msg of
        NoOp ->
            common.doNothing

        GoTo route ->
            common.justProduceCmd <| Route.navigateTo route

        OnRouteHit route ->
            case route of
                Route.BrowsePage ->
                    common.handleAll
                        [ performSearch True
                        , (\(Common common) ( model, shared ) ->
                            common.justProduceCmd <|
                                Cmd.batch
                                    [ (Util.domFocus (always NoOp) "search-bar")
                                    , if model.showAdvancedSearchOptions then
                                        Ports.expandSearchAdvancedOptions True
                                      else
                                        Cmd.none
                                    ]
                          )
                        ]

                _ ->
                    common.doNothing

        OnGetContentSuccess content ->
            case model.content of
                Nothing ->
                    common.justSetModel
                        { model
                            | content = Just content
                            , pageNumber = 2
                            , noMoreContent = isNoMoreContent 10 content
                        }

                Just currentContent ->
                    common.justSetModel
                        { model
                            | content = Just <| currentContent ++ content
                            , pageNumber = model.pageNumber + 1
                            , noMoreContent = isNoMoreContent 10 content
                        }

        OnGetContentFailure apiError ->
            common.justSetModalError apiError

        LoadMoreContent ->
            common.handleAll [ performSearch False ]

        OnUpdateSearch newSearchQuery ->
            common.handleAll
                [ -- Always update the model.
                  (\(Common common) ( model, shared ) ->
                    common.justSetModel { model | searchQuery = newSearchQuery }
                  )

                -- Only perform a search automatically if we're back to an empty search query.
                , (\(Common common) ( model, shared ) ->
                    if String.isEmpty newSearchQuery then
                        common.handleAll [ performSearch True ]
                    else
                        common.doNothing
                  )
                ]

        Search ->
            common.handleAll [ performSearch True ]

        ToggleAdvancedOptions ->
            ( { model | showAdvancedSearchOptions = not model.showAdvancedSearchOptions }
            , shared
            , Ports.expandSearchAdvancedOptions <| not model.showAdvancedSearchOptions
            )

        ToggleContentFilterSnipbits ->
            let
                updateFilterSnipbits (Common common) ( model, shared ) =
                    common.justSetModel { model | contentFilterSnipbits = not model.contentFilterSnipbits }
            in
                if (not model.contentFilterBigbits) && (not model.contentFilterStories) then
                    common.doNothing
                else
                    common.handleAll
                        [ updateFilterSnipbits
                        , performSearch True
                        ]

        ToggleContentFilterBigbits ->
            let
                updateFilterBigbits (Common common) ( model, shared ) =
                    common.justSetModel { model | contentFilterBigbits = not model.contentFilterBigbits }
            in
                if (not model.contentFilterSnipbits) && (not model.contentFilterStories) then
                    common.doNothing
                else
                    common.handleAll
                        [ updateFilterBigbits
                        , performSearch True
                        ]

        ToggleContentFilterStories ->
            let
                updateFilterStories (Common common) ( model, shared ) =
                    common.justSetModel { model | contentFilterStories = not model.contentFilterStories }
            in
                if (not model.contentFilterSnipbits) && (not model.contentFilterBigbits) then
                    common.doNothing
                else
                    common.handleAll
                        [ updateFilterStories
                        , performSearch True
                        ]

        SetIncludeEmptyStories includeEmptyStories ->
            let
                updateIncludeEmptyStories (Common common) ( model, shared ) =
                    common.justSetModel { model | contentFilterIncludeEmptyStories = includeEmptyStories }
            in
                common.handleAll
                    [ updateIncludeEmptyStories
                    , performSearch True
                    ]

        SelectLanguage maybeLanguage ->
            common.handleAll
                [ (\(Common common) ( model, shared ) ->
                    common.justSetModel { model | contentFilterLanguage = maybeLanguage }
                  )
                , performSearch True
                ]

        OnUpdateContentFilterAuthor newAuthorInput ->
            let
                wasAuthor =
                    model.contentFilterAuthor
                        |> Tuple.second
                        |> Util.isNotNothing
            in
                common.handleAll
                    [ -- We always update the model.
                      (\(Common common) ( model, shared ) ->
                        common.justSetModel { model | contentFilterAuthor = ( newAuthorInput, Nothing ) }
                      )

                    -- We only need to perform a search if their was an author before and we just cleared it.
                    , (\(Common common) ( model, shared ) ->
                        if wasAuthor then
                            common.handleAll [ performSearch True ]
                        else
                            common.doNothing
                      )

                    -- We need to check if the new input is a valid email, unless the new input is an empty string.
                    , (\(Common common) ( model, shared ) ->
                        if String.isEmpty newAuthorInput then
                            common.doNothing
                        else
                            common.justProduceCmd <|
                                common.api.get.userExists
                                    newAuthorInput
                                    OnGetUserExistsFailure
                                    (OnGetUserExistsSuccess << ((,) newAuthorInput))
                      )
                    ]

        OnGetUserExistsFailure apiError ->
            common.justSetModalError apiError

        OnGetUserExistsSuccess (( forEmail, maybeID ) as newContentFilterAuthor) ->
            -- The user may have typed more before the request returned, in which case we don't care about the request.
            if forEmail == (Tuple.first model.contentFilterAuthor) then
                common.handleAll
                    [ -- We always update the model.
                      (\(Common common) ( model, shared ) ->
                        common.justSetModel { model | contentFilterAuthor = newContentFilterAuthor }
                      )

                    -- If a valid email has been past then we perform a search (with the user filter).
                    , (\(Common common) ( model, shared ) ->
                        if Util.isNotNothing maybeID then
                            common.handleAll [ performSearch True ]
                        else
                            common.doNothing
                      )
                    ]
            else
                common.doNothing


{-| Performs a search based on `initialSearch` and the current model, handles updating the model.
-}
performSearch : Bool -> CommonSubPageUtil Model Shared Msg -> ( Model, Shared ) -> ( Model, Shared, Cmd Msg )
performSearch initialSearch (Common common) ( model, shared ) =
    let
        {- Get's the content with specific query params. -}
        getContent : QueryParams -> Cmd Msg
        getContent queryParams =
            common.api.get.content queryParams OnGetContentFailure OnGetContentSuccess

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
