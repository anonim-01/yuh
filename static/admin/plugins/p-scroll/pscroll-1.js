(function($) {
    "use strict";

    const element = document.querySelector('.sidebar-right');
    if (element) {
        new PerfectScrollbar(element, {
            useBothWheelAxes: true,
            suppressScrollX: true,
        });
    }

})(jQuery);