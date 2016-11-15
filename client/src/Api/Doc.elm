module Api.Doc exposing (CreateRequest, create)

import Api.Doc.Create
import Doc


type alias CreateRequest =
    Api.Doc.Create.Request


create : (CreateRequest -> msg) -> Doc.Model -> Cmd msg
create =
    Api.Doc.Create.cmd
