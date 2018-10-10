module Pages.Browse.Update exposing (..)

import Api exposing (api)
import DefaultServices.CommonSubPageUtil exposing (CommonSubPageUtil(..))
import DefaultServices.Util as Util
import Models.RequestTracker as RT
import Models.Route as Route
import Pages.Browse.Messages exposing (..)
import Pages.Browse.Model exposing (..)
import Pages.Messages as BaseMessage
import Pages.Model exposing (Shared)
import Ports
import ProjectTypeAliases exposing (..)


{-| `Browse` update.
-}
update : CommonSubPageUtil Model Shared Msg BaseMessage.Msg -> Msg -> Model -> Shared -> ( Model, Shared, Cmd BaseMessage.Msg )
update (Common common) msg model shared =
    case msg of
        OnRouteHit route ->
            case route of
                Route.BrowsePage ->
                    common.handleAll
                        [ resetPageNumber
                        , performSearch
                        , \(Common common) ( model, shared ) ->
                            common.justProduceCmd <|
                                Cmd.batch
                                    [ Util.domFocus (always BaseMessage.NoOp) "search-bar"
                                    , if model.showAdvancedSearchOptions then
                                        Ports.expandSearchAdvancedOptions True
                                      else
                                        Cmd.none
                                    ]
                        ]

                _ ->
                    common.doNothing

        OnGetContentSuccess searchSettings ( isMoreContent, content ) ->
            let
                isMostRecentRequest =
                    model.mostRecentSearchSettings == Just searchSettings

                getUpdatedModelForInitialRequest =
                    { model
                        | content = Just content
                        , pageNumber = 2
                        , noMoreContent = not isMoreContent
                    }

                getUpdatedModelForNonInitialRequest currentContent =
                    { model
                        | content = Just <| currentContent ++ content
                        , pageNumber = model.pageNumber + 1
                        , noMoreContent = not isMoreContent
                    }

                updatedModel =
                    if isMostRecentRequest then
                        case model.content of
                            Nothing ->
                                getUpdatedModelForInitialRequest

                            Just currentContent ->
                                -- This can happen if the user manages to switch his request settings so that as the
                                -- requests are about to come in he switches to those settings and makes a new request,
                                -- which won't happen because the request is already in progress but it will mark it as
                                -- the `mostRecentSearchSettings`. So the user could (in a very weird case) "catch"
                                -- multiple requests. So just to be sure, we check the page number and if it's the
                                -- first page we know to trash all current content which must only be there because of
                                -- a "caught" request.
                                if searchSettings.pageNumber == 1 then
                                    getUpdatedModelForInitialRequest
                                else
                                    getUpdatedModelForNonInitialRequest currentContent
                    else
                        model
            in
            common.justSetModel updatedModel
                |> common.andFinishRequest (RT.SearchForContent searchSettings)

        OnGetContentFailure searchSettings apiError ->
            common.justSetModalError apiError
                |> common.andFinishRequest (RT.SearchForContent searchSettings)

        LoadMoreContent ->
            common.handleAll [ performSearch ]

        OnUpdateSearch newSearchQuery ->
            common.handleAll
                [ -- Always update the model.
                  \(Common common) ( model, shared ) ->
                    common.justSetModel { model | searchQuery = newSearchQuery }

                -- Only perform a search automatically if we're back to an empty search query.
                , \(Common common) ( model, shared ) ->
                    if String.isEmpty newSearchQuery then
                        common.handleAll
                            [ resetPageNumber
                            , performSearch
                            ]
                    else
                        common.doNothing
                ]

        Search ->
            common.handleAll
                [ resetPageNumber
                , performSearch
                ]

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
            if not model.contentFilterBigbits && not model.contentFilterStories then
                common.doNothing
            else
                common.handleAll
                    [ updateFilterSnipbits
                    , resetPageNumber
                    , performSearch
                    ]

        ToggleContentFilterBigbits ->
            let
                updateFilterBigbits (Common common) ( model, shared ) =
                    common.justSetModel { model | contentFilterBigbits = not model.contentFilterBigbits }
            in
            if not model.contentFilterSnipbits && not model.contentFilterStories then
                common.doNothing
            else
                common.handleAll
                    [ updateFilterBigbits
                    , resetPageNumber
                    , performSearch
                    ]

        ToggleContentFilterStories ->
            let
                updateFilterStories (Common common) ( model, shared ) =
                    common.justSetModel { model | contentFilterStories = not model.contentFilterStories }
            in
            if not model.contentFilterSnipbits && not model.contentFilterBigbits then
                common.doNothing
            else
                common.handleAll
                    [ updateFilterStories
                    , resetPageNumber
                    , performSearch
                    ]

        SetIncludeEmptyStories includeEmptyStories ->
            let
                updateIncludeEmptyStories (Common common) ( model, shared ) =
                    common.justSetModel { model | contentFilterIncludeEmptyStories = includeEmptyStories }
            in
            common.handleAll
                [ updateIncludeEmptyStories
                , resetPageNumber
                , performSearch
                ]

        SelectLanguage maybeLanguage ->
            common.handleAll
                [ \(Common common) ( model, shared ) ->
                    common.justSetModel { model | contentFilterLanguage = maybeLanguage }
                , resetPageNumber
                , performSearch
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
                  \(Common common) ( model, shared ) ->
                    common.justSetModel { model | contentFilterAuthor = ( newAuthorInput, Nothing ) }

                -- We only need to perform a search if their was an author before and we just cleared it.
                , \(Common common) ( model, shared ) ->
                    if wasAuthor then
                        common.handleAll
                            [ resetPageNumber
                            , performSearch
                            ]
                    else
                        common.doNothing

                -- If the email is valid, check the database to see if a user exists with that email. If it's an
                -- invalid email we don't even need to check the database.
                , \(Common common) ( model, shared ) ->
                    if Util.isValidEmail newAuthorInput then
                        common.justProduceCmd <|
                            api.post.userExists
                                newAuthorInput
                                (common.subMsg << OnGetUserExistsFailure)
                                (common.subMsg << OnGetUserExistsSuccess << (,) newAuthorInput)
                    else
                        common.doNothing
                ]

        OnGetUserExistsFailure apiError ->
            common.justSetModalError apiError

        OnGetUserExistsSuccess (( forEmail, maybeID ) as newContentFilterAuthor) ->
            -- The user may have typed more before the request returned, in which case we don't care about the request.
            if forEmail == Tuple.first model.contentFilterAuthor then
                common.handleAll
                    [ -- We always update the model.
                      \(Common common) ( model, shared ) ->
                        common.justSetModel { model | contentFilterAuthor = newContentFilterAuthor }

                    -- If a valid email has been past then we perform a search (with the user filter).
                    , \(Common common) ( model, shared ) ->
                        if Util.isNotNothing maybeID then
                            common.handleAll
                                [ resetPageNumber
                                , performSearch
                                ]
                        else
                            common.doNothing
                    ]
            else
                common.doNothing


{-| Performs a search based on the current model, handles updating the model if needed.

NOTE (1):
Will track the request (including the `SearchSetting`s) and will avoid performing the search if an identical request is
already in progress.

NOTE (2):
Will also update `mostRecentSearchSettings` to keep track of what the most recent search request was, this allows us
to know what results from the server are still meaningful.

-}
performSearch : CommonSubPageUtil Model Shared Msg BaseMessage.Msg -> ( Model, Shared ) -> ( Model, Shared, Cmd BaseMessage.Msg )
performSearch (Common common) ( model, shared ) =
    let
        searchSettings : SearchSettings
        searchSettings =
            extractSearchSettingsFromModel model

        {- Get's the content with specific query params. -}
        getContent : QueryParams -> Cmd BaseMessage.Msg
        getContent queryParams =
            api.get.content
                queryParams
                (common.subMsg << OnGetContentFailure searchSettings)
                (common.subMsg << OnGetContentSuccess searchSettings)

        commonQueryParams =
            [ ( "includeSnipbits", Just <| Util.toJSBool searchSettings.includeSnipbits )
            , ( "includeBigbits", Just <| Util.toJSBool searchSettings.includeBigbits )
            , ( "includeStories", Just <| Util.toJSBool searchSettings.includeStories )
            , ( "includeEmptyStories", Just <| Util.toJSBool searchSettings.includeEmptyStories )
            , ( "restrictLanguage", searchSettings.restrictLanguage )
            , ( "author", searchSettings.author )
            , ( "pageNumber", Just <| toString searchSettings.pageNumber )
            ]

        currentRequest =
            RT.SearchForContent searchSettings

        ( newModel, newShared, newCmd ) =
            common.makeSingletonRequest currentRequest <|
                ( -- If it's the initial search, we reset a few fields, otherwise we leave the model the same.
                  if searchSettings.pageNumber == 1 then
                    { model
                        | showNewContentMessage = Util.isNothing searchSettings.searchQuery
                        , content = Nothing
                        , noMoreContent = False
                    }
                  else
                    model
                , shared
                , getContent <|
                    commonQueryParams
                        ++ (case searchSettings.searchQuery of
                                Nothing ->
                                    [ ( "sortByLastModified", Just "true" ) ]

                                Just searchQuery ->
                                    [ ( "searchQuery", Just searchQuery )
                                    , ( "sortByTextScore", Just "true" )
                                    ]
                           )
                )
    in
    -- Regardless of whether we actually performed the singleton request, we need to mark that it is the most
    -- recent request.
    ( { newModel | mostRecentSearchSettings = Just searchSettings }, newShared, newCmd )


{-| Resets the page number back to 1.
-}
resetPageNumber : CommonSubPageUtil Model Shared Msg BaseMessage.Msg -> ( Model, Shared ) -> ( Model, Shared, Cmd BaseMessage.Msg )
resetPageNumber (Common common) ( model, shared ) =
    common.justSetModel { model | pageNumber = 1 }
