(function($) {
    "use strict";

    const element = document.querySelector('.app-sidebar');
    if (element) {
        new PerfectScrollbar(element, {
            useBothWheelAxes: true,
            suppressScrollX: true,
            suppressScrollY: false,
        });
    }

    //P-scrolling
})(jQuery);