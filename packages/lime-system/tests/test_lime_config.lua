local config = require 'lime.config'
local test_utils = require 'tests.utils'

-- disable logging in config module
config.log = function() end

local uci = nil

describe('LiMe Config tests', function()

    it('test get/set_uci_cursor', function()
        local cursor = config.get_uci_cursor()
        assert.are.equal(config.get_uci_cursor(), cursor)
        config.set_uci_cursor('foo')
        assert.is.equal('foo', config.get_uci_cursor())
        --restore cursor
        config.set_uci_cursor(cursor)
    end)


    it('test empty get', function()
        assert.is_nil(config.get('section_foo', 'option_bar'))
    end)

    it('test simple get', function()
        uci:set(config.UCI_CONFIG_NAME, 'section_foo', 'type_foo')
        uci:set(config.UCI_CONFIG_NAME, 'section_foo', 'option_bar', 'value')
        assert.is.equal('value', config.get('section_foo', 'option_bar'))
    end)

    it('test get with fallback', function()
        assert.is.equal('fallback', config.get('section_foo', 'option_bar', 'fallback'))
    end)

    it('test get_bool', function()
        for _, value in pairs({'1', 'on', 'true', 'enabled'}) do
            uci:set(config.UCI_CONFIG_NAME, 'foo', 'type')
            uci:set(config.UCI_CONFIG_NAME, 'foo', 'bar', value)
            assert.is_true(config.get_bool('foo', 'bar'))
        end

        for _, value in pairs({'0', 'off', 'anything', 'false'}) do
            uci:set(config.UCI_CONFIG_NAME, 'foo', 'type')
            uci:set(config.UCI_CONFIG_NAME, 'foo', 'bar', value)
            assert.is_false(config.get_bool('foo', 'bar'))
        end
    end)

    it('test set', function()
        config.set('wlan0', 'type')
        config.set('wlan0', 'htmode', 'HT20')
        assert.is.equal('HT20', config.get('wlan0', 'htmode'))
        assert.is.equal('HT20', uci:get(config.UCI_CONFIG_NAME, 'wlan0', 'htmode'))
    end)

    it('test set nonstrings', function()
        -- convert integers to strings
        config.set('wifi', 'type')
        config.set('wifi', 'foo', 1)
        assert.is.equal('1', config.get('wifi', 'foo'))

        -- convert floats to strings
        config.set('wifi', 'foo', 1.9)
        assert.is.equal('1.9', config.get('wifi', 'foo'))

        -- convert booleans to strings
        config.set('wifi', 'foo', false)
        assert.is.equal('false', config.get('wifi', 'foo'))

        config.set('wifi', 'foo', true)
        assert.is.equal('true', config.get('wifi', 'foo'))
    end)

    it('test get_all', function()
        config.set('wifi', 'type')
        config.set('wifi', 'wlan0', '0')
        config.set('wifi', 'wlan1', '1')
        assert.is.equal('0', config.get_all('wifi').wlan0)
        assert.is.equal('1', config.get_all('wifi').wlan1)
    end)

    it('test get_all not storing into config/lime', function()
        uci:set('lime', 'wifi', 'type')
        uci:set('lime-defaults', 'wifi', 'type')
        uci:set('lime-defaults', 'wifi', 'wlan0', '0')
        uci:set('lime-defaults', 'wifi', 'wlan1', '1')

        assert.is.equal('0', config.get_all('wifi').wlan0)
        assert.is.equal('1', config.get_all('wifi').wlan1)

        assert.is_nil(config.uci:get('lime', 'wifi', 'wlan0'))

    end)

    it('test config.node_foreach only loading from config/lime with lime-defaults', function()
        uci:set('lime', 'wifi', 'type')
        uci:set('lime', 'wifi', 'wlan0', 'foo')
        uci:set('lime-defaults', 'wifi', 'type')
        uci:set('lime-defaults', 'wifi', 'wlan0', 'bar')
        uci:set('lime-defaults', 'wifi', 'wlan1', 'bar')
        local results = {}
        config.node_foreach('type', function(a) table.insert(results, a) end)

        assert.is.equal(1, #results)
        assert.is.equal('foo', results[1].wlan0)
    end)

    it('test config.node_foreach only loading from config/lime', function()
        uci:set('lime-defaults', 'wifi', 'type')
        uci:set('lime-defaults', 'wifi', 'wlan0', 'bar')
        local results = {}
        config.node_foreach('type', function(a) table.insert(results, a) end)

        assert.is.equal(0, #results)
    end)

    before_each('', function()
        uci = test_utils.setup_test_uci()
    end)

    after_each('', function()
        test_utils.teardown_test_uci(uci)
    end)
end)
