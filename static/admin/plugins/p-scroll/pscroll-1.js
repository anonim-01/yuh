(function($) {
    "use strict";

    const element = document.querySelector('.sidebar-right');
    if (element) {
        const ps11 = new PerfectScrollbar(element, {
            useBothWheelAxes: true,
            suppressScrollX: true,
        });
    }

})(jQuery);