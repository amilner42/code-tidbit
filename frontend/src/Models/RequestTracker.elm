module Models.RequestTracker exposing (..)

{- An extremely basic system for keeping track of what API requests are currently in progress. -}

import DefaultServices.InfixFunctions exposing (..)
import ProjectTypeAliases exposing (..)
import Dict


{-| All the requests that we are tracking.

NOTE: We will be `toString`ing these and using them as they key. So if you add parameters to the constructors, passing
in different parameters will result in different requests being tracked. Only use parameters if you specifically want
to track certain versions of a request differently.
-}
type TrackedRequest
    = LoginOrRegister
    | PublishNewStory


{-| A dictionary containing a count of all the requests currently in progress.
-}
type alias RequestTracker =
    Dict.Dict String Int


{-| Increments the count for the number of `TrackedRequest` currently being made.
-}
startRequest : TrackedRequest -> RequestTracker -> RequestTracker
startRequest trackedRequest =
    Dict.update
        (toString trackedRequest)
        (\maybeCount ->
            maybeCount
                ?> 0
                |> ((+) 1)
                |> Just
        )


{-| Decrements the count for the number of `TrackedRequest` being made.
-}
finishRequest : TrackedRequest -> RequestTracker -> RequestTracker
finishRequest trackedRequest =
    Dict.update
        (toString trackedRequest)
        (Maybe.andThen
            (\count ->
                if count - 1 >= 1 then
                    Just <| count - 1
                else
                    Nothing
            )
        )


{-| Get's the count for `TrackedRequest`.
-}
getRequestCount : RequestTracker -> TrackedRequest -> Int
getRequestCount requestTracker trackedRequest =
    Dict.get (toString trackedRequest) requestTracker
        ?> 0


{-| Returns true if at least 1 `TrackedRequest` is currently being made.
-}
isMakingRequest : RequestTracker -> TrackedRequest -> Bool
isMakingRequest requestTracker requestName =
    getRequestCount requestTracker requestName
        |> (\count -> count >= 1)


{-| Returns true if there are no requests currently being made (opposite of `isMakingRequest`).
-}
isNotMakingRequest : RequestTracker -> TrackedRequest -> Bool
isNotMakingRequest requestTracker trackedRequest =
    not <| isMakingRequest requestTracker trackedRequest
