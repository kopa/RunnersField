using  Toybox.System as Sys;

//! A circular queue implementation.
class DataQueue {

    //! the data array.
    var data;
    var maxSize = 0;
    var pos = 0;
    var size = 0;

    //! precondition: size has to be >= 2
    function initialize(arraySize) {
        data = new[arraySize];
        maxSize = arraySize;
    }
    
    //! Add an element to the queue.
    function add(element) {
        data[pos] = element;
        pos = (pos + 1) % maxSize;
        if (size < maxSize) {
            size++;
        }
    }
    
    //! Reset the queue to its initial state.
    function reset() {
        if (size > 0) {
            for (var i = 0; i < data.size(); i++) {
                data[i] = null;
            }
            size = 0;
            pos = 0;
        }
    }
    
    //! Get the underlying data array.
    function getData() {
        return data;
    }
    
    //! Get the actual element count in the queue.
    function getSize() {
        return size;
    }
}