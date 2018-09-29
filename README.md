# Dom.DragDrop

This library makes it easy to implement HTML5 drag-and-drop operations with Elm and
[@danielnarey's elm-dom framework](https://github.com/danielnarey/elm-modular-ui/).

Dom.Element nodes can be made draggable and droppable, with the state represented by an opaque object you can store in your model.

Each draggable/droppable element should correspond to some kind of id. This could be an (id for an) item in a list, a tag value from a type representing the various draggable/droppable elements, or whatever you want.

Your application must provide messages for each of the events triggered by this framework. The library provides helper methods to query and update the current state.

More documentation, examples, and tests coming soon!
