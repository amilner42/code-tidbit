module Api exposing (API, api)

import Date
import DefaultServices.Http as HttpService
import DefaultServices.Util as Util
import JSON.BasicResponse
import JSON.Bigbit
import JSON.Completed
import JSON.Content
import JSON.ContentPointer
import JSON.IDResponse
import JSON.Opinion
import JSON.QA
import JSON.Range
import JSON.Rating
import JSON.Snipbit
import JSON.Story
import JSON.Tidbit
import JSON.TidbitPointer
import JSON.User
import JSON.Vote
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Json.Encode as Encode
import Models.ApiError as ApiError
import Models.BasicResponse as BasicResponse
import Models.Bigbit as Bigbit
import Models.Completed as Completed
import Models.Content as Content
import Models.ContentPointer as ContentPointer
import Models.IDResponse as IDResponse
import Models.Opinion as Opinion
import Models.QA as QA
import Models.Range as Range
import Models.Rating as Rating
import Models.Snipbit as Snipbit
import Models.Story as Story
import Models.Tidbit as Tidbit
import Models.TidbitPointer as TidbitPointer
import Models.User as User
import Models.Vote as Vote
import Pages.CreateBigbit.JSON as CreateBigbitJSON
import Pages.CreateBigbit.Model as CreateBigbitModel
import Pages.CreateSnipbit.JSON as CreateSnipbitJSON
import Pages.CreateSnipbit.Model as CreateSnipbitModel
import ProjectTypeAliases exposing (..)


{-| The API to access the backend.
-}
type alias API b =
    { get :
        { userExists : Email -> (ApiError.ApiError -> b) -> (Maybe UserID -> b) -> Cmd b
        , userExistsWrapper : Email -> (ApiError.ApiError -> b) -> (( Email, Maybe UserID ) -> b) -> Cmd b
        , account : (ApiError.ApiError -> b) -> (User.User -> b) -> Cmd b
        , stories : QueryParams -> (ApiError.ApiError -> b) -> (List Story.Story -> b) -> Cmd b
        , story : StoryID -> (ApiError.ApiError -> b) -> (Story.Story -> b) -> Cmd b
        , expandedStory : StoryID -> (ApiError.ApiError -> b) -> (Story.ExpandedStory -> b) -> Cmd b
        , expandedStoryWithCompleted : StoryID -> (ApiError.ApiError -> b) -> (Story.ExpandedStory -> b) -> Cmd b
        , logOut : (ApiError.ApiError -> b) -> (BasicResponse.BasicResponse -> b) -> Cmd b
        , snipbit : SnipbitID -> (ApiError.ApiError -> b) -> (Snipbit.Snipbit -> b) -> Cmd b
        , bigbit : BigbitID -> (ApiError.ApiError -> b) -> (Bigbit.Bigbit -> b) -> Cmd b
        , tidbits : QueryParams -> (ApiError.ApiError -> b) -> (List Tidbit.Tidbit -> b) -> Cmd b
        , content : QueryParams -> (ApiError.ApiError -> b) -> (List Content.Content -> b) -> Cmd b
        , opinion : ContentPointer.ContentPointer -> (ApiError.ApiError -> b) -> (Maybe Rating.Rating -> b) -> Cmd b
        , opinionWrapper : ContentPointer.ContentPointer -> (ApiError.ApiError -> b) -> (Opinion.PossibleOpinion -> b) -> Cmd b
        , snipbitQA : SnipbitID -> (ApiError.ApiError -> b) -> (QA.SnipbitQA -> b) -> Cmd b
        , bigbitQA : BigbitID -> (ApiError.ApiError -> b) -> (QA.BigbitQA -> b) -> Cmd b
        }
    , post :
        { login : User.UserForLogin -> (ApiError.ApiError -> b) -> (User.User -> b) -> Cmd b
        , register : User.UserForRegistration -> (ApiError.ApiError -> b) -> (User.User -> b) -> Cmd b
        , createSnipbit : CreateSnipbitModel.SnipbitForPublication -> (ApiError.ApiError -> b) -> (IDResponse.IDResponse -> b) -> Cmd b
        , createBigbit : CreateBigbitModel.BigbitForPublication -> (ApiError.ApiError -> b) -> (IDResponse.IDResponse -> b) -> Cmd b
        , updateUser : User.UserUpdateRecord -> (ApiError.ApiError -> b) -> (User.User -> b) -> Cmd b
        , createNewStory : Story.NewStory -> (ApiError.ApiError -> b) -> (IDResponse.IDResponse -> b) -> Cmd b
        , updateStoryInformation : StoryID -> Story.NewStory -> (ApiError.ApiError -> b) -> (IDResponse.IDResponse -> b) -> Cmd b
        , addTidbitsToStory : StoryID -> List TidbitPointer.TidbitPointer -> (ApiError.ApiError -> b) -> (Story.ExpandedStory -> b) -> Cmd b
        , addCompleted : Completed.Completed -> (ApiError.ApiError -> b) -> (IDResponse.IDResponse -> b) -> Cmd b
        , addCompletedWrapper : Completed.Completed -> (ApiError.ApiError -> b) -> (Completed.IsCompleted -> b) -> Cmd b
        , removeCompleted : Completed.Completed -> (ApiError.ApiError -> b) -> (Bool -> b) -> Cmd b
        , removeCompletedWrapper : Completed.Completed -> (ApiError.ApiError -> b) -> (Completed.IsCompleted -> b) -> Cmd b
        , checkCompleted : Completed.Completed -> (ApiError.ApiError -> b) -> (Bool -> b) -> Cmd b
        , checkCompletedWrapper : Completed.Completed -> (ApiError.ApiError -> b) -> (Completed.IsCompleted -> b) -> Cmd b
        , addOpinion : Opinion.Opinion -> (ApiError.ApiError -> b) -> (Bool -> b) -> Cmd b
        , addOpinionWrapper : Opinion.Opinion -> (ApiError.ApiError -> b) -> (Opinion.Opinion -> b) -> Cmd b
        , removeOpinion : Opinion.Opinion -> (ApiError.ApiError -> b) -> (Bool -> b) -> Cmd b
        , removeOpinionWrapper : Opinion.Opinion -> (ApiError.ApiError -> b) -> (Opinion.Opinion -> b) -> Cmd b
        , askQuestionOnSnipbit : SnipbitID -> QuestionText -> Range.Range -> (ApiError.ApiError -> b) -> (QA.Question Range.Range -> b) -> Cmd b
        , askQuestionOnSnipbitWrapper : SnipbitID -> QuestionText -> Range.Range -> (ApiError.ApiError -> b) -> (SnipbitID -> QA.Question Range.Range -> b) -> Cmd b
        , askQuestionOnBigbit : BigbitID -> QuestionText -> QA.BigbitCodePointer -> (ApiError.ApiError -> b) -> (QA.Question QA.BigbitCodePointer -> b) -> Cmd b
        , editQuestionOnSnipbit : SnipbitID -> QuestionID -> QuestionText -> Range.Range -> (ApiError.ApiError -> b) -> (Date.Date -> b) -> Cmd b
        , editQuestionOnBigbit : BigbitID -> QuestionID -> QuestionText -> QA.BigbitCodePointer -> (ApiError.ApiError -> b) -> (Date.Date -> b) -> Cmd b
        , deleteQuestion : TidbitPointer.TidbitPointer -> QuestionID -> (ApiError.ApiError -> b) -> (() -> b) -> Cmd b
        , rateQuestion : TidbitPointer.TidbitPointer -> QuestionID -> Vote.Vote -> (ApiError.ApiError -> b) -> (() -> b) -> Cmd b
        , removeQuestionRating : TidbitPointer.TidbitPointer -> QuestionID -> (ApiError.ApiError -> b) -> (() -> b) -> Cmd b
        , pinQuestion : TidbitPointer.TidbitPointer -> QuestionID -> Bool -> (ApiError.ApiError -> b) -> (() -> b) -> Cmd b
        , answerQuestion : TidbitPointer.TidbitPointer -> QuestionID -> AnswerText -> (ApiError.ApiError -> b) -> (QA.Answer -> b) -> Cmd b
        , editAnswer : TidbitPointer.TidbitPointer -> AnswerID -> AnswerText -> (ApiError.ApiError -> b) -> (Date.Date -> b) -> Cmd b
        , deleteAnswer : TidbitPointer.TidbitPointer -> AnswerID -> (ApiError.ApiError -> b) -> (() -> b) -> Cmd b
        , rateAnswer : TidbitPointer.TidbitPointer -> AnswerID -> Vote.Vote -> (ApiError.ApiError -> b) -> (() -> b) -> Cmd b
        , removeAnswerRating : TidbitPointer.TidbitPointer -> AnswerID -> (ApiError.ApiError -> b) -> (() -> b) -> Cmd b
        , pinAnswer : TidbitPointer.TidbitPointer -> AnswerID -> Bool -> (ApiError.ApiError -> b) -> (() -> b) -> Cmd b
        , commentOnQuestion : TidbitPointer.TidbitPointer -> QuestionID -> CommentText -> (ApiError.ApiError -> b) -> (QA.QuestionComment -> b) -> Cmd b
        , editQuestionComment : TidbitPointer.TidbitPointer -> CommentID -> CommentText -> (ApiError.ApiError -> b) -> (Date.Date -> b) -> Cmd b
        , deleteQuestionComment : TidbitPointer.TidbitPointer -> CommentID -> (ApiError.ApiError -> b) -> (() -> b) -> Cmd b
        , commentOnAnswer : TidbitPointer.TidbitPointer -> QuestionID -> AnswerID -> CommentText -> (ApiError.ApiError -> b) -> (QA.AnswerComment -> b) -> Cmd b
        , editAnswerComment : TidbitPointer.TidbitPointer -> CommentID -> CommentText -> (ApiError.ApiError -> b) -> (Date.Date -> b) -> Cmd b
        , deleteAnswerComment : TidbitPointer.TidbitPointer -> CommentID -> (ApiError.ApiError -> b) -> (() -> b) -> Cmd b
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
        getUserExists : Email -> (ApiError.ApiError -> b) -> (Maybe UserID -> b) -> Cmd b
        getUserExists email =
            apiGet ("userID" :/: email) (Decode.maybe Decode.string)

        {- Gets the users account, or an error if unauthenticated. -}
        getAccount : (ApiError.ApiError -> b) -> (User.User -> b) -> Cmd b
        getAccount =
            apiGet "account" JSON.User.decoder

        {- Gets all the stories, you can use query params to customize the search. Refer to the backend route to see
           what the options are.
        -}
        getStories : QueryParams -> (ApiError.ApiError -> b) -> (List Story.Story -> b) -> Cmd b
        getStories queryParams =
            apiGet
                ("stories" ++ Util.queryParamsToString queryParams)
                (Decode.list <| JSON.Story.decoder)

        {- Gets a single story. -}
        getStory : StoryID -> (ApiError.ApiError -> b) -> (Story.Story -> b) -> Cmd b
        getStory storyID =
            apiGet
                ("stories" :/: storyID)
                JSON.Story.decoder

        {- Get's a user's opinion. -}
        getOpinion : ContentPointer.ContentPointer -> (ApiError.ApiError -> b) -> (Maybe Rating.Rating -> b) -> Cmd b
        getOpinion contentPointer =
            apiGet
                ("account/getOpinion"
                    :/: (toString <| JSON.ContentPointer.contentTypeToInt contentPointer.contentType)
                    :/: (contentPointer.contentID)
                )
                (Decode.maybe JSON.Rating.decoder)

        {- Gets a single expanded story. -}
        getExpandedStory : StoryID -> (ApiError.ApiError -> b) -> (Story.ExpandedStory -> b) -> Cmd b
        getExpandedStory storyID =
            apiGet
                ("stories" :/: storyID ++ Util.queryParamsToString [ ( "expandStory", Just "true" ) ])
                JSON.Story.expandedStoryDecoder

        {- Gets a single expanded story with the completed list attached. -}
        getExpandedStoryWithCompleted : StoryID -> (ApiError.ApiError -> b) -> (Story.ExpandedStory -> b) -> Cmd b
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
        getSnipbit : SnipbitID -> (ApiError.ApiError -> b) -> (Snipbit.Snipbit -> b) -> Cmd b
        getSnipbit snipbitID =
            apiGet ("snipbits" :/: snipbitID) JSON.Snipbit.decoder

        {- Get's a bigbit. -}
        getBigbit : BigbitID -> (ApiError.ApiError -> b) -> (Bigbit.Bigbit -> b) -> Cmd b
        getBigbit bigbitID =
            apiGet ("bigbits" :/: bigbitID) JSON.Bigbit.decoder

        {- Gets tidbits, you can use query params to customize the search. Refer to the backend to see what the options are. -}
        getTidbits : QueryParams -> (ApiError.ApiError -> b) -> (List Tidbit.Tidbit -> b) -> Cmd b
        getTidbits queryParams =
            apiGet
                ("tidbits" ++ (Util.queryParamsToString queryParams))
                (Decode.list JSON.Tidbit.decoder)

        {- Get's content, you can use query params to customize the search. Refer to the backend to see what the options are. -}
        getContent : QueryParams -> (ApiError.ApiError -> b) -> (List Content.Content -> b) -> Cmd b
        getContent queryParams =
            apiGet
                ("content" ++ (Util.queryParamsToString queryParams))
                (Decode.list JSON.Content.decoder)

        {- Get's the QA object for a specific snipbit (`qa/1` because 1 is the access point for snipbits' QA). -}
        getSnipbitQA : SnipbitID -> (ApiError.ApiError -> b) -> (QA.SnipbitQA -> b) -> Cmd b
        getSnipbitQA snipbitID =
            apiGet ("qa/1" :/: snipbitID) JSON.QA.snipbitQADecoder

        {- Get's the QA object for a specific bigbit (`qa/2` because 2 is the access point for bigbits' QA). -}
        getBigbitQA : BigbitID -> (ApiError.ApiError -> b) -> (QA.BigbitQA -> b) -> Cmd b
        getBigbitQA bigbitID =
            apiGet ("qa/2" :/: bigbitID) JSON.QA.bigbitQADecoder

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
        postUpdateStoryInformation : StoryID -> Story.NewStory -> (ApiError.ApiError -> b) -> (IDResponse.IDResponse -> b) -> Cmd b
        postUpdateStoryInformation storyID newStoryInformation =
            apiPost
                ("stories" :/: storyID :/: "information")
                JSON.IDResponse.decoder
                (JSON.Story.newStoryEncoder newStoryInformation)

        {- Updates a story with new tidbits. -}
        postAddTidbitsToStory : StoryID -> List TidbitPointer.TidbitPointer -> (ApiError.ApiError -> b) -> (Story.ExpandedStory -> b) -> Cmd b
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

        {- Adds an opinion for a logged-in user. -}
        postAddOpinion : Opinion.Opinion -> (ApiError.ApiError -> b) -> (Bool -> b) -> Cmd b
        postAddOpinion opinion =
            apiPost
                "account/addOpinion"
                Decode.bool
                (JSON.Opinion.encoder opinion)

        {- Removes an opinion for a logged-in user. -}
        postRemoveOpinion : Opinion.Opinion -> (ApiError.ApiError -> b) -> (Bool -> b) -> Cmd b
        postRemoveOpinion opinion =
            apiPost
                "account/removeOpinion"
                Decode.bool
                (JSON.Opinion.encoder opinion)

        {- Ask a question on a snipbit. -}
        postAskQuestionOnSnipbit : SnipbitID -> QuestionText -> Range.Range -> (ApiError.ApiError -> b) -> (QA.Question Range.Range -> b) -> Cmd b
        postAskQuestionOnSnipbit snipbitID questionText codePointer =
            apiPost
                ("qa/1" :/: snipbitID :/: "askQuestion")
                (JSON.QA.questionDecoder JSON.Range.decoder)
                (Encode.object
                    [ ( "questionText", Encode.string questionText )
                    , ( "codePointer", JSON.Range.encoder codePointer )
                    ]
                )

        {- Ask a question on a bigbit. -}
        postAskQuestionOnBigbit : BigbitID -> QuestionText -> QA.BigbitCodePointer -> (ApiError.ApiError -> b) -> (QA.Question QA.BigbitCodePointer -> b) -> Cmd b
        postAskQuestionOnBigbit bigbitID questionText codePointer =
            apiPost
                ("qa/2" :/: bigbitID :/: "askQuestion")
                (JSON.QA.questionDecoder JSON.QA.bigbitCodePointerDecoder)
                (Encode.object
                    [ ( "questionText", Encode.string questionText )
                    , ( "codePointer", JSON.QA.bigbitCodePointerEncoder codePointer )
                    ]
                )

        {- Edit a question on a snipbit. -}
        postEditQuestionOnSnipbit : SnipbitID -> QuestionID -> QuestionText -> Range.Range -> (ApiError.ApiError -> b) -> (Date.Date -> b) -> Cmd b
        postEditQuestionOnSnipbit snipbitID questionID questionText codePointer =
            apiPost
                ("qa/1" :/: snipbitID :/: "editQuestion")
                Util.dateDecoder
                (Encode.object
                    [ ( "questionID", Encode.string questionID )
                    , ( "questionText", Encode.string questionText )
                    , ( "codePointer", JSON.Range.encoder codePointer )
                    ]
                )

        {- Edit a question on a bigbit. -}
        postEditQuestionOnBigbit : BigbitID -> QuestionID -> QuestionText -> QA.BigbitCodePointer -> (ApiError.ApiError -> b) -> (Date.Date -> b) -> Cmd b
        postEditQuestionOnBigbit bigbitID questionID questionText codePointer =
            apiPost
                ("qa/2" :/: bigbitID :/: "editQuestion")
                Util.dateDecoder
                (Encode.object
                    [ ( "questionID", Encode.string questionID )
                    , ( "questionText", Encode.string questionText )
                    , ( "codePointer", JSON.QA.bigbitCodePointerEncoder codePointer )
                    ]
                )

        {- Deletes a question. -}
        postDeleteQuestion : TidbitPointer.TidbitPointer -> QuestionID -> (ApiError.ApiError -> b) -> (() -> b) -> Cmd b
        postDeleteQuestion tidbitPointer questionID =
            apiPost
                ("qa" :/: (tidbitPointerToUrl tidbitPointer) :/: "deleteQuestion")
                (decode ())
                (Encode.object [ ( "questionID", Encode.string questionID ) ])

        {- Place your vote (`Vote`) on a question. -}
        postRateQuestion : TidbitPointer.TidbitPointer -> QuestionID -> Vote.Vote -> (ApiError.ApiError -> b) -> (() -> b) -> Cmd b
        postRateQuestion tidbitPointer questionID vote =
            apiPost
                ("qa" :/: (tidbitPointerToUrl tidbitPointer) :/: "rateQuestion")
                (decode ())
                (Encode.object
                    [ ( "questionID", Encode.string questionID )
                    , ( "vote", JSON.Vote.encoder vote )
                    ]
                )

        {- Remove a rating from a question. -}
        postRemoveQuestionRating : TidbitPointer.TidbitPointer -> QuestionID -> (ApiError.ApiError -> b) -> (() -> b) -> Cmd b
        postRemoveQuestionRating tidbitPointer questionID =
            apiPost
                ("qa" :/: (tidbitPointerToUrl tidbitPointer) :/: "removeQuestionRating")
                (decode ())
                (Encode.object [ ( "questionID", Encode.string questionID ) ])

        {- Sets the pin-state of a question. -}
        postPinQuestion : TidbitPointer.TidbitPointer -> QuestionID -> Bool -> (ApiError.ApiError -> b) -> (() -> b) -> Cmd b
        postPinQuestion tidbitPointer questionID pin =
            apiPost
                ("qa" :/: (tidbitPointerToUrl tidbitPointer) :/: "pinQuestion")
                (decode ())
                (Encode.object
                    [ ( "questionID", Encode.string questionID )
                    , ( "pin", Encode.bool pin )
                    ]
                )

        {- Answer a question. -}
        postAnswerQuestion : TidbitPointer.TidbitPointer -> QuestionID -> AnswerText -> (ApiError.ApiError -> b) -> (QA.Answer -> b) -> Cmd b
        postAnswerQuestion tidbitPointer questionID answerText =
            apiPost
                ("qa" :/: (tidbitPointerToUrl tidbitPointer) :/: "answerQuestion")
                JSON.QA.answerDecoder
                (Encode.object
                    [ ( "questionID", Encode.string questionID )
                    , ( "answerText", Encode.string answerText )
                    ]
                )

        {- Edit an answer. -}
        postEditAnswer : TidbitPointer.TidbitPointer -> AnswerID -> AnswerText -> (ApiError.ApiError -> b) -> (Date.Date -> b) -> Cmd b
        postEditAnswer tidbitPointer answerID answerText =
            apiPost
                ("qa" :/: (tidbitPointerToUrl tidbitPointer) :/: "editAnswer")
                Util.dateDecoder
                (Encode.object
                    [ ( "answerID", Encode.string answerID )
                    , ( "answerText", Encode.string answerText )
                    ]
                )

        {- Deletes an answer. -}
        postDeleteAnswer : TidbitPointer.TidbitPointer -> AnswerID -> (ApiError.ApiError -> b) -> (() -> b) -> Cmd b
        postDeleteAnswer tidbitPointer answerID =
            apiPost
                ("qa" :/: (tidbitPointerToUrl tidbitPointer) :/: "deleteAnswer")
                (decode ())
                (Encode.object [ ( "answerID", Encode.string answerID ) ])

        {- Rates an answer. -}
        postRateAnswer : TidbitPointer.TidbitPointer -> AnswerID -> Vote.Vote -> (ApiError.ApiError -> b) -> (() -> b) -> Cmd b
        postRateAnswer tidbitPointer answerID vote =
            apiPost
                ("qa" :/: (tidbitPointerToUrl tidbitPointer) :/: "rateAnswer")
                (decode ())
                (Encode.object
                    [ ( "answerID", Encode.string answerID )
                    , ( "vote", JSON.Vote.encoder vote )
                    ]
                )

        {- Removes a rating from an answer. -}
        postRemoveAnswerRating : TidbitPointer.TidbitPointer -> AnswerID -> (ApiError.ApiError -> b) -> (() -> b) -> Cmd b
        postRemoveAnswerRating tidbitPointer answerID =
            apiPost
                ("qa" :/: (tidbitPointerToUrl tidbitPointer) :/: "removeAnswerRating")
                (decode ())
                (Encode.object [ ( "answerID", Encode.string answerID ) ])

        {- Sets the pin-state of an answer. -}
        postPinAnswer : TidbitPointer.TidbitPointer -> AnswerID -> Bool -> (ApiError.ApiError -> b) -> (() -> b) -> Cmd b
        postPinAnswer tidbitPointer answerID pin =
            apiPost
                ("qa" :/: (tidbitPointerToUrl tidbitPointer) :/: "pinAnswer")
                (decode ())
                (Encode.object
                    [ ( "answerID", Encode.string answerID )
                    , ( "pin", Encode.bool pin )
                    ]
                )

        {- Comment on a question (adds to the existing comment thread). -}
        postCommentOnQuestion : TidbitPointer.TidbitPointer -> QuestionID -> CommentText -> (ApiError.ApiError -> b) -> (QA.QuestionComment -> b) -> Cmd b
        postCommentOnQuestion tidbitPointer questionID commentText =
            apiPost
                ("qa" :/: (tidbitPointerToUrl tidbitPointer) :/: "comment/question")
                (JSON.QA.questionCommentDecoder)
                (Encode.object
                    [ ( "questionID", Encode.string questionID )
                    , ( "commentText", Encode.string commentText )
                    ]
                )

        {- Edit a comment on a question. -}
        postEditQuestionComment : TidbitPointer.TidbitPointer -> CommentID -> CommentText -> (ApiError.ApiError -> b) -> (Date.Date -> b) -> Cmd b
        postEditQuestionComment tidbitPointer commentID commentText =
            apiPost
                ("qa" :/: (tidbitPointerToUrl tidbitPointer) :/: "editComment/question")
                Util.dateDecoder
                (Encode.object
                    [ ( "commentText", Encode.string commentText )
                    , ( "commentID", Encode.string commentID )
                    ]
                )

        {- Deletes a comment on a question. -}
        postDeleteQuestionComment : TidbitPointer.TidbitPointer -> CommentID -> (ApiError.ApiError -> b) -> (() -> b) -> Cmd b
        postDeleteQuestionComment tidbitPointer commentID =
            apiPost
                ("qa" :/: (tidbitPointerToUrl tidbitPointer) :/: "deleteComment/question")
                (decode ())
                (Encode.object [ ( "commentID", Encode.string commentID ) ])

        {- Comment on an answer. -}
        postCommentOnAnswer : TidbitPointer.TidbitPointer -> QuestionID -> AnswerID -> CommentText -> (ApiError.ApiError -> b) -> (QA.AnswerComment -> b) -> Cmd b
        postCommentOnAnswer tidbitPointer questionID answerID commentText =
            apiPost
                ("qa" :/: (tidbitPointerToUrl tidbitPointer) :/: "comment/answer")
                JSON.QA.answerCommentDecoder
                (Encode.object
                    [ ( "questionID", Encode.string questionID )
                    , ( "answerID", Encode.string answerID )
                    , ( "commentText", Encode.string commentText )
                    ]
                )

        {- Edit a comment on an answer. -}
        postEditAnswerComment : TidbitPointer.TidbitPointer -> CommentID -> CommentText -> (ApiError.ApiError -> b) -> (Date.Date -> b) -> Cmd b
        postEditAnswerComment tidbitPointer commentID commentText =
            apiPost
                ("qa" :/: (tidbitPointerToUrl tidbitPointer) :/: "editComment/answer")
                Util.dateDecoder
                (Encode.object
                    [ ( "commentID", Encode.string commentID )
                    , ( "commentText", Encode.string commentText )
                    ]
                )

        postDeleteAnswerComment : TidbitPointer.TidbitPointer -> CommentID -> (ApiError.ApiError -> b) -> (() -> b) -> Cmd b
        postDeleteAnswerComment tidbitPointer commentID =
            apiPost
                ("qa" :/: (tidbitPointerToUrl tidbitPointer) :/: "deleteComment/answer")
                (decode ())
                (Encode.object [ ( "commentID", Encode.string commentID ) ])

        -- API Request Wrappers
        {- Wrapper around `getOpinion`, returns in `Opinion` form using the inputs. -}
        getOpinionWrapper : ContentPointer.ContentPointer -> (ApiError.ApiError -> b) -> (Opinion.PossibleOpinion -> b) -> Cmd b
        getOpinionWrapper contentPointer handleError handleSuccess =
            getOpinion
                contentPointer
                handleError
                (Opinion.PossibleOpinion contentPointer >> handleSuccess)

        {- Wrapper around `getUserExists` that also returns the email that was passed in. -}
        getUserExistsWrapper : Email -> (ApiError.ApiError -> b) -> (( Email, Maybe UserID ) -> b) -> Cmd b
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

        {- Wrapper around `postAddOpinion` to return the opinion that was just added. -}
        postAddOpinionWrapper : Opinion.Opinion -> (ApiError.ApiError -> b) -> (Opinion.Opinion -> b) -> Cmd b
        postAddOpinionWrapper opinion handleError handleSuccess =
            postAddOpinion
                opinion
                handleError
                (always <| handleSuccess opinion)

        {- Wrapper around `postRemoveOpinion` that returns the removed opinion. -}
        postRemoveOpinionWrapper : Opinion.Opinion -> (ApiError.ApiError -> b) -> (Opinion.Opinion -> b) -> Cmd b
        postRemoveOpinionWrapper opinion handleError handleSuccess =
            postRemoveOpinion
                opinion
                handleError
                (always <| handleSuccess opinion)

        {- Wrapper around `postAskQuestionOnSnipbit` that also returns the snipbitID. -}
        postAskQuestionOnSnipbitWrapper : SnipbitID -> QuestionText -> Range.Range -> (ApiError.ApiError -> b) -> (SnipbitID -> QA.Question Range.Range -> b) -> Cmd b
        postAskQuestionOnSnipbitWrapper snipbitID questionText range handleError handleSuccess =
            postAskQuestionOnSnipbit
                snipbitID
                questionText
                range
                handleError
                (handleSuccess snipbitID)
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
            , opinion = getOpinion
            , opinionWrapper = getOpinionWrapper
            , snipbitQA = getSnipbitQA
            , bigbitQA = getBigbitQA
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
            , addOpinion = postAddOpinion
            , addOpinionWrapper = postAddOpinionWrapper
            , removeOpinion = postRemoveOpinion
            , removeOpinionWrapper = postRemoveOpinionWrapper
            , askQuestionOnSnipbit = postAskQuestionOnSnipbit
            , askQuestionOnSnipbitWrapper = postAskQuestionOnSnipbitWrapper
            , askQuestionOnBigbit = postAskQuestionOnBigbit
            , editQuestionOnSnipbit = postEditQuestionOnSnipbit
            , editQuestionOnBigbit = postEditQuestionOnBigbit
            , deleteQuestion = postDeleteQuestion
            , rateQuestion = postRateQuestion
            , removeQuestionRating = postRemoveQuestionRating
            , pinQuestion = postPinQuestion
            , answerQuestion = postAnswerQuestion
            , editAnswer = postEditAnswer
            , deleteAnswer = postDeleteAnswer
            , rateAnswer = postRateAnswer
            , removeAnswerRating = postRemoveAnswerRating
            , pinAnswer = postPinAnswer
            , commentOnQuestion = postCommentOnQuestion
            , editQuestionComment = postEditQuestionComment
            , deleteQuestionComment = postDeleteQuestionComment
            , commentOnAnswer = postCommentOnAnswer
            , editAnswerComment = postEditAnswerComment
            , deleteAnswerComment = postDeleteAnswerComment
            }
        }


{-| For adding a slash in a URL.
-}
(:/:) : String -> String -> String
(:/:) str1 str2 =
    str1 ++ "/" ++ str2


{-| Converts tidbit pointers to the standard URL format: "<tidbitTypeToInt>/<tidbitID>"
-}
tidbitPointerToUrl : TidbitPointer.TidbitPointer -> String
tidbitPointerToUrl { tidbitType, targetID } =
    (toString <| JSON.TidbitPointer.tidbitTypeToInt tidbitType) :/: targetID
