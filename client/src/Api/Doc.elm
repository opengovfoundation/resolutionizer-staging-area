module Api.Doc exposing (CreateResponse, create)

import Api.Doc.Create
import Doc
import RemoteData


type alias CreateResponse =
    Api.Doc.Create.Response


create : (RemoteData.WebData CreateResponse -> msg) -> Doc.Model -> Cmd msg
create =
    Api.Doc.Create.cmd
