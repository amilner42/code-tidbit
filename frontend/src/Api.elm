module Api exposing (API, api)

import DefaultServices.Http as HttpService
import DefaultServices.Util as Util
import JSON.BasicResponse
import JSON.Bigbit
import JSON.Completed
import JSON.Content
import JSON.IDResponse
import JSON.Snipbit
import JSON.Story
import JSON.Tidbit
import JSON.TidbitPointer
import JSON.User
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Json.Encode as Encode
import Models.ApiError as ApiError
import Models.BasicResponse as BasicResponse
import Models.Bigbit as Bigbit
import Models.Completed as Completed
import Models.Content as Content
import Models.IDResponse as IDResponse
import Models.Snipbit as Snipbit
import Models.Story as Story
import Models.Tidbit as Tidbit
import Models.TidbitPointer as TidbitPointer
import Models.User as User
import Pages.CreateBigbit.JSON as CreateBigbitJSON
import Pages.CreateBigbit.Model as CreateBigbitModel
import Pages.CreateSnipbit.JSON as CreateSnipbitJSON
import Pages.CreateSnipbit.Model as CreateSnipbitModel


{-| The API to access the backend.
-}
type alias API b =
    { get :
        { userExists : String -> (ApiError.ApiError -> b) -> (Maybe String -> b) -> Cmd b
        , userExistsWrapper : String -> (ApiError.ApiError -> b) -> (( String, Maybe String ) -> b) -> Cmd b
        , account : (ApiError.ApiError -> b) -> (User.User -> b) -> Cmd b
        , stories : List ( String, Maybe String ) -> (ApiError.ApiError -> b) -> (List Story.Story -> b) -> Cmd b
        , story : String -> (ApiError.ApiError -> b) -> (Story.Story -> b) -> Cmd b
        , expandedStory : String -> (ApiError.ApiError -> b) -> (Story.ExpandedStory -> b) -> Cmd b
        , expandedStoryWithCompleted : String -> (ApiError.ApiError -> b) -> (Story.ExpandedStory -> b) -> Cmd b
        , logOut : (ApiError.ApiError -> b) -> (BasicResponse.BasicResponse -> b) -> Cmd b
        , snipbit : String -> (ApiError.ApiError -> b) -> (Snipbit.Snipbit -> b) -> Cmd b
        , bigbit : String -> (ApiError.ApiError -> b) -> (Bigbit.Bigbit -> b) -> Cmd b
        , tidbits : List ( String, Maybe String ) -> (ApiError.ApiError -> b) -> (List Tidbit.Tidbit -> b) -> Cmd b
        , content : List ( String, Maybe String ) -> (ApiError.ApiError -> b) -> (List Content.Content -> b) -> Cmd b
        }
    , post :
        { login : User.UserForLogin -> (ApiError.ApiError -> b) -> (User.User -> b) -> Cmd b
        , register : User.UserForRegistration -> (ApiError.ApiError -> b) -> (User.User -> b) -> Cmd b
        , createSnipbit : CreateSnipbitModel.SnipbitForPublication -> (ApiError.ApiError -> b) -> (IDResponse.IDResponse -> b) -> Cmd b
        , createBigbit : CreateBigbitModel.BigbitForPublication -> (ApiError.ApiError -> b) -> (IDResponse.IDResponse -> b) -> Cmd b
        , updateUser : User.UserUpdateRecord -> (ApiError.ApiError -> b) -> (User.User -> b) -> Cmd b
        , createNewStory : Story.NewStory -> (ApiError.ApiError -> b) -> (IDResponse.IDResponse -> b) -> Cmd b
        , updateStoryInformation : String -> Story.NewStory -> (ApiError.ApiError -> b) -> (IDResponse.IDResponse -> b) -> Cmd b
        , addTidbitsToStory : String -> List TidbitPointer.TidbitPointer -> (ApiError.ApiError -> b) -> (Story.ExpandedStory -> b) -> Cmd b
        , addCompleted : Completed.Completed -> (ApiError.ApiError -> b) -> (IDResponse.IDResponse -> b) -> Cmd b
        , addCompletedWrapper : Completed.Completed -> (ApiError.ApiError -> b) -> (Completed.IsCompleted -> b) -> Cmd b
        , removeCompleted : Completed.Completed -> (ApiError.ApiError -> b) -> (Bool -> b) -> Cmd b
        , removeCompletedWrapper : Completed.Completed -> (ApiError.ApiError -> b) -> (Completed.IsCompleted -> b) -> Cmd b
        , checkCompleted : Completed.Completed -> (ApiError.ApiError -> b) -> (Bool -> b) -> Cmd b
        , checkCompletedWrapper : Completed.Completed -> (ApiError.ApiError -> b) -> (Completed.IsCompleted -> b) -> Cmd b
        }
    }


{-| The access point to the API.

Currently takes the API base url as configuration (different in prod and dev).
-}
api : String -> API b
api apiBaseUrl =
    let
        {- Helper for querying the API (GET), automatically adds the apiBaseUrl prefix. -}
        apiGet : String -> Decode.Decoder a -> (ApiError.ApiError -> b) -> (a -> b) -> Cmd b
        apiGet url =
            HttpService.get (apiBaseUrl ++ url)

        {- Helper for qeurying the API (POST), automatically adds the apiBaseUrl prefix. -}
        apiPost : String -> Decode.Decoder a -> Encode.Value -> (ApiError.ApiError -> b) -> (a -> b) -> Cmd b
        apiPost url =
            HttpService.post (apiBaseUrl ++ url)

        {- Gets the ID of the user that exists with that email (if one exists, otherwise returns `Nothing`). -}
        getUserExists : String -> (ApiError.ApiError -> b) -> (Maybe String -> b) -> Cmd b
        getUserExists email =
            apiGet ("userID" :/: email) (Decode.maybe Decode.string)

        {- Gets the users account, or an error if unauthenticated. -}
        getAccount : (ApiError.ApiError -> b) -> (User.User -> b) -> Cmd b
        getAccount =
            apiGet "account" JSON.User.decoder

        {- Gets all the stories, you can use query params to customize the search. Refer to the backend route to see
           what the options are.
        -}
        getStories : List ( String, Maybe String ) -> (ApiError.ApiError -> b) -> (List Story.Story -> b) -> Cmd b
        getStories queryParams =
            apiGet
                ("stories" ++ Util.queryParamsToString queryParams)
                (Decode.list <| JSON.Story.decoder)

        {- Gets a single story. -}
        getStory : String -> (ApiError.ApiError -> b) -> (Story.Story -> b) -> Cmd b
        getStory storyID =
            apiGet
                ("stories" :/: storyID)
                JSON.Story.decoder

        {- Gets a single expanded story. -}
        getExpandedStory : String -> (ApiError.ApiError -> b) -> (Story.ExpandedStory -> b) -> Cmd b
        getExpandedStory storyID =
            apiGet
                ("stories" :/: storyID ++ Util.queryParamsToString [ ( "expandStory", Just "true" ) ])
                JSON.Story.expandedStoryDecoder

        {- Gets a single expanded story with the completed list attached. -}
        getExpandedStoryWithCompleted : String -> (ApiError.ApiError -> b) -> (Story.ExpandedStory -> b) -> Cmd b
        getExpandedStoryWithCompleted storyID =
            apiGet
                ("stories"
                    :/: storyID
                    ++ Util.queryParamsToString
                        [ ( "expandStory", Just "true" )
                        , ( "withCompleted", Just "true" )
                        ]
                )
                JSON.Story.expandedStoryDecoder

        {- Queries the API to log the user out, which should send a response to delete the cookies. -}
        getLogOut : (ApiError.ApiError -> b) -> (BasicResponse.BasicResponse -> b) -> Cmd b
        getLogOut =
            apiGet "logOut" JSON.BasicResponse.decoder

        {- Get's a snipbit. -}
        getSnipbit : String -> (ApiError.ApiError -> b) -> (Snipbit.Snipbit -> b) -> Cmd b
        getSnipbit snipbitID =
            apiGet ("snipbits" :/: snipbitID) JSON.Snipbit.decoder

        {- Get's a bigbit. -}
        getBigbit : String -> (ApiError.ApiError -> b) -> (Bigbit.Bigbit -> b) -> Cmd b
        getBigbit bigbitID =
            apiGet ("bigbits" :/: bigbitID) JSON.Bigbit.decoder

        {- Gets tidbits, you can use query params to customize the search. Refer to the backend to see what the options are. -}
        getTidbits : List ( String, Maybe String ) -> (ApiError.ApiError -> b) -> (List Tidbit.Tidbit -> b) -> Cmd b
        getTidbits queryParams =
            apiGet
                ("tidbits" ++ (Util.queryParamsToString queryParams))
                (Decode.list JSON.Tidbit.decoder)

        {- Get's content, you can use query params to customize the search. Refer to the backend to see what the options are. -}
        getContent : List ( String, Maybe String ) -> (ApiError.ApiError -> b) -> (List Content.Content -> b) -> Cmd b
        getContent queryParams =
            apiGet
                ("content" ++ (Util.queryParamsToString queryParams))
                (Decode.list JSON.Content.decoder)

        {- Logs user in and returns the user, unless invalid credentials. -}
        postLogin : User.UserForLogin -> (ApiError.ApiError -> b) -> (User.User -> b) -> Cmd b
        postLogin user =
            apiPost "login" JSON.User.decoder (JSON.User.loginEncoder user)

        {- Registers the user and returns the user, unless invalid new credentials. -}
        postRegister : User.UserForRegistration -> (ApiError.ApiError -> b) -> (User.User -> b) -> Cmd b
        postRegister user =
            apiPost "register" JSON.User.decoder (JSON.User.registerEncoder user)

        {- Creates a new snipbit. -}
        postCreateSnipbit : CreateSnipbitModel.SnipbitForPublication -> (ApiError.ApiError -> b) -> (IDResponse.IDResponse -> b) -> Cmd b
        postCreateSnipbit snipbit =
            apiPost
                "snipbits"
                JSON.IDResponse.decoder
                (CreateSnipbitJSON.publicationEncoder snipbit)

        {- Creates a new bigbit. -}
        postCreateBigbit : CreateBigbitModel.BigbitForPublication -> (ApiError.ApiError -> b) -> (IDResponse.IDResponse -> b) -> Cmd b
        postCreateBigbit bigbit =
            apiPost
                "bigbits"
                JSON.IDResponse.decoder
                (CreateBigbitJSON.publicationEncoder bigbit)

        {- Updates a user. -}
        postUpdateUser : User.UserUpdateRecord -> (ApiError.ApiError -> b) -> (User.User -> b) -> Cmd b
        postUpdateUser updateRecord =
            apiPost
                "account"
                JSON.User.decoder
                (JSON.User.updateRecordEncoder updateRecord)

        {- Creates a new story. -}
        postCreateNewStory : Story.NewStory -> (ApiError.ApiError -> b) -> (IDResponse.IDResponse -> b) -> Cmd b
        postCreateNewStory newStory =
            apiPost
                "stories"
                JSON.IDResponse.decoder
                (JSON.Story.newStoryEncoder newStory)

        {- Updates the information for a story. -}
        postUpdateStoryInformation : String -> Story.NewStory -> (ApiError.ApiError -> b) -> (IDResponse.IDResponse -> b) -> Cmd b
        postUpdateStoryInformation storyID newStoryInformation =
            apiPost
                ("stories" :/: storyID :/: "information")
                JSON.IDResponse.decoder
                (JSON.Story.newStoryEncoder newStoryInformation)

        {- Updates a story with new tidbits. -}
        postAddTidbitsToStory : String -> List TidbitPointer.TidbitPointer -> (ApiError.ApiError -> b) -> (Story.ExpandedStory -> b) -> Cmd b
        postAddTidbitsToStory storyID newTidbitPointers =
            apiPost
                ("stories" :/: storyID :/: "addTidbits")
                JSON.Story.expandedStoryDecoder
                (Encode.list <| List.map JSON.TidbitPointer.encoder newTidbitPointers)

        {- Adds a new `Completed` to the list of things the user has completed. -}
        postAddCompleted : Completed.Completed -> (ApiError.ApiError -> b) -> (IDResponse.IDResponse -> b) -> Cmd b
        postAddCompleted completed =
            apiPost
                "account/addCompleted"
                JSON.IDResponse.decoder
                (JSON.Completed.encoder completed)

        {- Removes a `Completed` from the users list of completed tidbits. -}
        postRemoveCompleted : Completed.Completed -> (ApiError.ApiError -> b) -> (Bool -> b) -> Cmd b
        postRemoveCompleted completed =
            apiPost
                "account/removeCompleted"
                Decode.bool
                (JSON.Completed.encoder completed)

        {- Checks if something is completed, does not modify the db. -}
        postCheckCompleted : Completed.Completed -> (ApiError.ApiError -> b) -> (Bool -> b) -> Cmd b
        postCheckCompleted completed =
            apiPost
                "account/checkCompleted"
                Decode.bool
                (JSON.Completed.encoder completed)

        -- API Request Wrappers
        {- Wrapper around `getUserExists` that also returns the email that was passed in. -}
        getUserExistsWrapper : String -> (ApiError.ApiError -> b) -> (( String, Maybe String ) -> b) -> Cmd b
        getUserExistsWrapper email handleError handleSuccess =
            getUserExists
                email
                handleError
                (((,) email) >> handleSuccess)

        {- Wrapper around `postAddCompleted`, returns the result in `IsComplete` form using the input to get
           that information.
        -}
        postAddCompletedWrapper : Completed.Completed -> (ApiError.ApiError -> b) -> (Completed.IsCompleted -> b) -> Cmd b
        postAddCompletedWrapper completed handleError handleSuccess =
            postAddCompleted
                completed
                handleError
                (always <| handleSuccess <| Completed.IsCompleted completed.tidbitPointer True)

        {- Wrapper around `postRemoveCompleted`, returns the result in `IsComplete` form using the input to get that
           information.
        -}
        postRemoveCompletedWrapper : Completed.Completed -> (ApiError.ApiError -> b) -> (Completed.IsCompleted -> b) -> Cmd b
        postRemoveCompletedWrapper completed handleError handleSuccess =
            postRemoveCompleted
                completed
                handleError
                (always <| handleSuccess <| Completed.IsCompleted completed.tidbitPointer False)

        {- Wrapper around `postCheckCompleted`, returns the result in `IsComplete` form using the input to get that
           information.
        -}
        postCheckCompletedWrapper : Completed.Completed -> (ApiError.ApiError -> b) -> (Completed.IsCompleted -> b) -> Cmd b
        postCheckCompletedWrapper completed handleError handleSuccess =
            postCheckCompleted
                completed
                handleError
                (Completed.IsCompleted completed.tidbitPointer >> handleSuccess)
    in
        { get =
            { userExists = getUserExists
            , userExistsWrapper = getUserExistsWrapper
            , account = getAccount
            , stories = getStories
            , story = getStory
            , expandedStory = getExpandedStory
            , expandedStoryWithCompleted = getExpandedStoryWithCompleted
            , logOut = getLogOut
            , snipbit = getSnipbit
            , bigbit = getBigbit
            , tidbits = getTidbits
            , content = getContent
            }
        , post =
            { login = postLogin
            , register = postRegister
            , createSnipbit = postCreateSnipbit
            , createBigbit = postCreateBigbit
            , updateUser = postUpdateUser
            , createNewStory = postCreateNewStory
            , updateStoryInformation = postUpdateStoryInformation
            , addTidbitsToStory = postAddTidbitsToStory
            , addCompleted = postAddCompleted
            , addCompletedWrapper = postAddCompletedWrapper
            , removeCompleted = postRemoveCompleted
            , removeCompletedWrapper = postRemoveCompletedWrapper
            , checkCompleted = postCheckCompleted
            , checkCompletedWrapper = postCheckCompletedWrapper
            }
        }


{-| For adding a slash in a URL.
-}
(:/:) : String -> String -> String
(:/:) str1 str2 =
    str1 ++ "/" ++ str2
