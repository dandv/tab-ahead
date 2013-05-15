/*global window*/
(function ($, fuzzy, chrome) {
    'use strict';

    // Put together `typeahead` options.
    var string_separator = ':::::',
        all_colons = /:/g,
        fuzzy_options = {
            pre: '<strong class="text-info">',
            post: '</strong>',
            extract: function (el) {
                return el.title + string_separator + el.url;
            }
        },
        source = function (query, process) {

            chrome.windows.getCurrent({populate: true}, function (current_window) {

                var results = fuzzy.filter(query.replace(all_colons, ''), current_window.tabs, fuzzy_options);

                process(results);

            });

        },
        matcher = function (item) {
            return true;
        },
        sorter = function (items) {
            return items;
        },
        highlighter = function (item) {

            var matches = item.string.split(string_separator),
                title_highlighted = matches[0],
                url_highlighted = matches[1],
                result = '<div class="title">' + title_highlighted + '</div>' + '<small class="muted url">' + url_highlighted + '</small>';

            return result;
        },
        updater = function (item) {

            chrome.tabs.update(item.original.id, {
                selected: true
            });

            return item.original.title;
        };

    //
    // Quick and dirty monkey patch
    // implementing `$.fn.data` instead of
    // using `$.fn.attr('data-value')`
    // to be able to handle `item` objects
    // instead of simple strings.
    //
    $.fn.typeahead.Constructor.prototype.render = function (items) {
        var that = this;

        items = $(items).map(function (i, item) {
            i = $(that.options.item).data('value', item); // Monkey patched.
            i.find('a').html(that.highlighter(item));
            return i[0];
        });

        items.first().addClass('active');
        this.$menu.html(items);
        return this;
    };
    $.fn.typeahead.Constructor.prototype.select = function () {
        var val = this.$menu.find('.active').data('value'); // Monkey patched.

        this.$element.val(this.updater(val)).change();
        return this.hide();
    };

    // Init `typeahead`.
    $('#typeahead').typeahead({
        updater: updater,
        source: source,
        matcher: matcher,
        sorter: sorter,
        highlighter: highlighter,
        items: 10
    });

    // Do not `submit` form,
    // but reset input to empty string.
    $('form').on('submit', function (e) {
        $('#typeahead').val('');
        return false;
    });

}(window.jQuery, window.fuzzy, window.chrome));
