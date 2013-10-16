describe 'Tab Ahead. Popup', ->

    # Mocking birds
    window.chrome =
        windows:
            getCurrent: (options, callback) ->
                $.getJSON 'base/test/fixtures/window.json', (data) ->
                    callback data
        tabs:
            update: (tabId, updateProperties, callback) ->
                callback()

    beforeEach ->
        setFixtures window.__html__['test/fixtures/form.html']
        window.tabahead window.jQuery, window.fuzzy, window.chrome, window.setTimeout

    describe 'loaded without exploding', ->
        it 'is available', ->
            (expect window.tabahead).toBeDefined()
            (expect window.tabahead).toEqual jasmine.any Function

    describe 'expects the chrome environment', ->
        it 'expects to find a form.navbar-search', ->
            (expect $ 'body').toContain 'form.navbar-search'

        it 'expects to find an input#typeahead', ->
            (expect $ 'form.navbar-search').toContain 'input#typeahead'

    describe 'Initially the input', ->
        it 'should be focused', ->
            (expect $ 'input#typeahead').toBeFocused()

    describe 'Typing some text into the input field', ->
        getCurrentWindowSpy = {}

        beforeEach ->
            getCurrentWindowSpy = (spyOn window.chrome.windows, 'getCurrent').andCallThrough()

            $('#typeahead')
                .val('jan')
                .trigger('keyup')

        it 'should ask chrome API for current window', ->
            (expect getCurrentWindowSpy).toHaveBeenCalled()

        it 'should show suggestions', ->
            waitsFor ->
                ($ 'ul').length > 0

            runs ->
                (expect $ 'ul').toHaveLength(1)

                # Add `\n` due to `new line at the end of the fixture.
                (expect ($ 'ul').html() + '\n').toBe window.__html__['test/fixtures/suggestions.html']

    describe 'Selecting a suggestion', ->
        closeSpy = {}
        updateSpy = {}
        item = {}
        li = {}

        beforeEach ->
            updateSpy = (spyOn window.chrome.tabs, 'update').andCallThrough()
            closeSpy = spyOn window, 'close'

            $('#typeahead')
                .val('jan')
                .trigger('keyup')

            waitsFor ->
                ($ 'ul').length > 0

        describe 'by hitting return', ->
            beforeEach ->
                li = $ 'li:nth-child(1)'
                item = li.data 'value'

                jasmine.Clock.useMock()

                $('input').trigger($.Event 'keyup', keyCode: 13)

                jasmine.Clock.tick 100

            it 'should update the tab and close the window', ->
                (expect updateSpy).toHaveBeenCalled()
                (expect updateSpy.mostRecentCall.args[0]).toBe item.original.id
                (expect updateSpy.mostRecentCall.args[1]).toEqual active:true
                (expect updateSpy.mostRecentCall.args[2]).toEqual jasmine.any Function
                (expect closeSpy).toHaveBeenCalled()


        describe 'by click', ->
            beforeEach ->
                li = $ 'li:nth-child(2)'
                item = li.data 'value'

                jasmine.Clock.useMock()

                ($ li).trigger 'mouseenter'
                ($ li).trigger 'click'

                jasmine.Clock.tick 200

            it 'should update the tab and close the window', ->
                (expect updateSpy).toHaveBeenCalled()
                (expect updateSpy.mostRecentCall.args[0]).toBe item.original.id
                (expect updateSpy.mostRecentCall.args[1]).toEqual active:true
                (expect updateSpy.mostRecentCall.args[2]).toEqual jasmine.any Function
                (expect closeSpy).toHaveBeenCalled()

    describe 'If there is no match', ->
        updateSpy = {}

        beforeEach ->
            updateSpy = spyOn window.chrome.tabs, 'update'

            $('#typeahead')
                .val('jan')
                .trigger('keyup')

            waitsFor ->
                ($ 'ul').length > 0

        describe 'hitting enter', ->
            beforeEach ->
                $('#typeahead')
                    .val('janjanjanjanjanjanjanjan')
                    .trigger('keyup')

                waitsFor ->
                    ($ 'ul').is(':hidden')
                runs ->
                    jasmine.Clock.useMock()
                    ($ '#typeahead').trigger($.Event 'keyup', keyCode: 13)
                    jasmine.Clock.tick 100

            it 'should not update the tab', ->
                (expect updateSpy).not.toHaveBeenCalled()

            it 'should clear the input', ->
                ($ '#typeahead').trigger('submit')
                (expect ($ '#typeahead').val()).toBe ''



