# Dom.DragDrop

This library makes it easy to implement HTML5 drag-and-drop operations with Elm and
[@danielnarey's elm-dom framework](https://github.com/visotype/elm-dom/).

## Data

Each draggable element and element you can drop stuff onto ("drop target") has an identifier. Often, these will be based on  the ID of some record, but don't have to be. Here's an example from the, well, [example](https://github.com/arsduo/ui-drag-drop/tree/master/example/MovableObjects.elm#L30):

```elm
{- Let's say have a list of records. -}
type Id = Id Int

{- These records are the only draggable elements, so we can use their IDs as the draggable identifier type. -}
type DraggableId
    = DraggableId Id


{- Users can drop onto either a specific element in the list (taking that spot) or move it to the end of the list. -}
type DropTarget
    = OntoElement Id
    | EndOfList
```

If your application had certain hard-coded draggable items, you could imagine draggable type like
this:

```elm
type DraggableElementId =
  LaserPointer
  | ChewToy

type DropTarget =
  Cat
  | Dog

```

All this data gets wrapped up into an opaque object you can store in your model. You learn about
the current state using various [helper method](https://github.com/arsduo/ui-drag-drop/tree/master/src/Dom/DragDrop.elm):

```elm
model =
  { dragDropState : DragDrop.State DraggableId DropTarget }

{- Is something currently being dragged? Returns a (Maybe DraggableId). }
Dom.DragDrop.currentlyDraggedObject model.dragDropState

{- Is there currently a dragged element atop a drop target? Returns a Bool. -}
Dom.DragDrop.dropTargetExists model.dragDropState

{- and so on -}
```


## Messages

Your application must define messages for the four events triggered by this framework. Here are
the examples again

```elm
type Msg
    = MoveStarted DraggableId
    | MoveTargetChanged DropTarget
    | MoveCanceled
    | MoveCompleted DraggableId DropTarget

{- You provide these messages when making an element draggable or droppable -}
dragDropMessages : Dom.DragDrop.Messages Id DropTarget
dragDropMessages =
    { dragStarted = MoveStarted
    , dropTargetChanged = MoveTargetChanged
    , dragEnded = MoveCanceled
    , dropped = MoveCompleted
```

## Required Javascript

Sadly, a bit of Javascript is required to make dragging and dropping work. Fortunately, you don't
need to set up any ports -- just some simple event listeners on the `body` will take care of the
event handling:

```js
document.body.addEventListener("dragstart", event => {
  if (event.target && event.target.draggable) {
    // absurdly, this is needed for Firefox; see https://medium.com/elm-shorts/elm-drag-and-drop-game-630205556d2
    event.dataTransfer.setData("text/html", "blank");
  }
});

document.body.addEventListener("dragover", event => {
  // this is needed in order to make dragging work
  return false;
});
```

## Example!

Check out the example to see how this works!

Clone this repo and run `yarn example`. You can then navigate to [http://localhost:8080/example](http://localhost:8080/example) to see Dom.DragDrop in action!


## Contributing

See a bug? Want to add a feature? Awesome!

Building the library locally is simple: you use the example to easily test your changes or add your local copy of the package to your Elm app's `sources` to develop in your own app.

When filing an issue, please include a good description of what's happening and screenshots (if possible). Code to reproduce the issue would be much appreciated.

Please note that this project is released with a Contributor Code of Conduct. By participating in
this project you agree to abide by its terms. See
[code-of-conduct.md](https://github.com/arsduo/ui-drag-drop/blob/master/code-of-conduct.md) for more information.

