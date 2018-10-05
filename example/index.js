// index.js
"use strict";

import Elm from "./Stuff.elm";
const mountNode = document.getElementById("elm-app");
const app = Elm.Stuff.embed(mountNode);
