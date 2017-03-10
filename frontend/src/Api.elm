module Api exposing (..)

import Config exposing (apiBaseUrl)
import DefaultServices.Http as HttpService
import DefaultServices.Util as Util
import Json.Decode as Decode
import Json.Encode as Encode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Models.ApiError as ApiError
import Models.BasicResponse as BasicResponse
import Models.Bigbit as Bigbit
import Models.Completed as Completed
import Models.IDResponse as IDResponse
import Models.Snipbit as Snipbit
import Models.Story as Story
import Models.User as User
import Models.Tidbit as Tidbit
import Models.TidbitPointer as TidbitPointer


{-| Helper for querying the API (GET), automatically adds the apiBaseUrl prefix.
-}
apiGet : String -> Decode.Decoder a -> (ApiError.ApiError -> b) -> (a -> b) -> Cmd b
apiGet url =
    HttpService.get (apiBaseUrl ++ url)


{-| Helper for qeurying the API (POST), automatically adds the apiBaseUrl prefix.
-}
apiPost : String -> Decode.Decoder a -> Encode.Value -> (ApiError.ApiError -> b) -> (a -> b) -> Cmd b
apiPost url =
    HttpService.post (apiBaseUrl ++ url)


{-| Gets the users account, or an error if unauthenticated.
-}
getAccount : (ApiError.ApiError -> b) -> (User.User -> b) -> Cmd b
getAccount =
    apiGet "account" User.decoder


{-| Gets all the stories, you can use query params to customize the search.
Refer to the backend route to see what the options are.
-}
getStories : List ( String, Maybe String ) -> (ApiError.ApiError -> b) -> (List Story.Story -> b) -> Cmd b
getStories queryParams =
    apiGet
        ("stories" ++ Util.queryParamsToString queryParams)
        (Decode.list <| Story.storyDecoder)


{-| Gets a single story.
-}
getStory : String -> (ApiError.ApiError -> b) -> (Story.Story -> b) -> Cmd b
getStory storyID =
    apiGet
        ("stories" :/: storyID)
        Story.storyDecoder


{-| Gets a single expanded story.
-}
getExpandedStory : String -> (ApiError.ApiError -> b) -> (Story.ExpandedStory -> b) -> Cmd b
getExpandedStory storyID =
    apiGet
        ("stories" :/: storyID ++ Util.queryParamsToString [ ( "expandStory", Just "true" ) ])
        Story.expandedStoryDecoder


{-| Gets a single expanded story with the completed.
-}
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
        Story.expandedStoryDecoder


{-| Queries the API to log the user out, which should send a response to delete
the cookies.
-}
getLogOut : (ApiError.ApiError -> b) -> (BasicResponse.BasicResponse -> b) -> Cmd b
getLogOut =
    apiGet "logOut" BasicResponse.decoder


{-| For adding a slash in a URL.
-}
(:/:) : String -> String -> String
(:/:) str1 str2 =
    str1 ++ "/" ++ str2


{-| Get's a snipbit.
-}
getSnipbit : String -> (ApiError.ApiError -> b) -> (Snipbit.Snipbit -> b) -> Cmd b
getSnipbit snipbitID =
    apiGet ("snipbits" :/: snipbitID) Snipbit.snipbitDecoder


{-| Get's a bigbit.
-}
getBigbit : String -> (ApiError.ApiError -> b) -> (Bigbit.Bigbit -> b) -> Cmd b
getBigbit bigbitID =
    apiGet ("bigbits" :/: bigbitID) Bigbit.bigbitDecoder


{-| Gets tidbits, you can use query params to customize the search.
Refer to the backend to see what the options are.
-}
getTidbits : List ( String, Maybe String ) -> (ApiError.ApiError -> b) -> (List Tidbit.Tidbit -> b) -> Cmd b
getTidbits queryParams =
    apiGet
        ("tidbits" ++ (Util.queryParamsToString queryParams))
        (Decode.list Tidbit.decoder)


{-| Logs user in and returns the user, unless invalid credentials.
-}
postLogin : User.UserForLogin -> (ApiError.ApiError -> b) -> (User.User -> b) -> Cmd b
postLogin user =
    apiPost "login" User.decoder (User.userLoginEncoder user)


{-| Registers the user and returns the user, unless invalid new credentials.
-}
postRegister : User.UserForRegistration -> (ApiError.ApiError -> b) -> (User.User -> b) -> Cmd b
postRegister user =
    apiPost "register" User.decoder (User.userRegisterEncoder user)


{-| Creates a new snipbit.
-}
postCreateSnipbit : Snipbit.SnipbitForPublication -> (ApiError.ApiError -> b) -> (IDResponse.IDResponse -> b) -> Cmd b
postCreateSnipbit snipbit =
    apiPost
        "snipbits"
        IDResponse.idResponseDecoder
        (Snipbit.snipbitForPublicationEncoder snipbit)


{-| Creates a new bigbit.
-}
postCreateBigbit : Bigbit.BigbitForPublication -> (ApiError.ApiError -> b) -> (IDResponse.IDResponse -> b) -> Cmd b
postCreateBigbit bigbit =
    apiPost
        "bigbits"
        IDResponse.idResponseDecoder
        (Bigbit.bigbitForPublicationEncoder bigbit)


{-| Updates a user.
-}
postUpdateUser : User.UserUpdateRecord -> (ApiError.ApiError -> b) -> (User.User -> b) -> Cmd b
postUpdateUser updateRecord =
    apiPost
        "account"
        User.decoder
        (User.userUpdateRecordEncoder updateRecord)


{-| Creates a new story.
-}
postCreateNewStory : Story.NewStory -> (ApiError.ApiError -> b) -> (IDResponse.IDResponse -> b) -> Cmd b
postCreateNewStory newStory =
    apiPost
        "stories"
        IDResponse.idResponseDecoder
        (Story.newStoryEncoder newStory)


{-| Updates the information for a story.
-}
postUpdateStoryInformation : String -> Story.NewStory -> (ApiError.ApiError -> b) -> (IDResponse.IDResponse -> b) -> Cmd b
postUpdateStoryInformation storyID newStoryInformation =
    apiPost
        ("stories" :/: storyID :/: "information")
        IDResponse.idResponseDecoder
        (Story.newStoryEncoder newStoryInformation)


{-| Updates a story with new tidbits.
-}
postAddTidbitsToStory : String -> List TidbitPointer.TidbitPointer -> (ApiError.ApiError -> b) -> (Story.ExpandedStory -> b) -> Cmd b
postAddTidbitsToStory storyID newTidbitPointers =
    apiPost
        ("stories" :/: storyID :/: "addTidbits")
        Story.expandedStoryDecoder
        (Encode.list <| List.map TidbitPointer.encoder newTidbitPointers)


{-| Adds a new `Completed` to the list of things the user has completed.
-}
postAddCompleted : Completed.Completed -> (ApiError.ApiError -> b) -> (IDResponse.IDResponse -> b) -> Cmd b
postAddCompleted completed =
    apiPost
        "account/addCompleted"
        IDResponse.idResponseDecoder
        (Completed.encoder completed)


{-| Removs a `Completed` from the users list of completed tidbits.
-}
postRemoveCompleted : Completed.Completed -> (ApiError.ApiError -> b) -> (Bool -> b) -> Cmd b
postRemoveCompleted completed =
    apiPost
        "account/removeCompleted"
        Decode.bool
        (Completed.encoder completed)


{-| Checks if something is completed, does not modify the db.
-}
postCheckCompleted : Completed.Completed -> (ApiError.ApiError -> b) -> (Completed.IsCompleted -> b) -> Cmd b
postCheckCompleted completed =
    apiPost
        "account/checkCompleted"
        (Completed.isCompletedFromBoolDecoder completed.tidbitPointer)
        (Completed.encoder completed)



-- API Request Wrappers


{-| Wrapper around `postAddCompleted`, returns the result in `IsComplete` form
using the input to get that information.
-}
wrapPostAddCompleted : Completed.Completed -> (ApiError.ApiError -> b) -> (Completed.IsCompleted -> b) -> Cmd b
wrapPostAddCompleted completed handleError handleSuccess =
    postAddCompleted
        completed
        handleError
        (always <| handleSuccess <| Completed.IsCompleted completed.tidbitPointer True)


{-| Wrapper around `postRemoveCompleted`, returns the result in `IsComplete`
form using the input to get that information.
-}
wrapPostRemoveCompleted : Completed.Completed -> (ApiError.ApiError -> b) -> (Completed.IsCompleted -> b) -> Cmd b
wrapPostRemoveCompleted completed handleError handleSuccess =
    postRemoveCompleted
        completed
        handleError
        (always <| handleSuccess <| Completed.IsCompleted completed.tidbitPointer False)
