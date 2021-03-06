require 'spec_helper'

describe Napybara::DSL do
  let(:capybara_page) do
    Capybara.string <<-HTML
      <form class='some-form'>
        <button class='some-button'>
          <img />
        </button>

        <button class='another-button'>
          <img />
        </button>
      </form>
    HTML
  end

  describe '.build' do
    it 'returns the capybara_page as is' do
      element = described_class.build(capybara_page)
      expect(element).to eq(capybara_page)
    end

    it 'adds child elements from the block to the return element' do
      element = described_class.build(capybara_page) do
        find :form, '.some-form'
      end

      expect(element.form['class']).to eq('some-form')
    end
  end

  describe '#find' do
    it 'adds a method to the element for finding the given selector' do
      dsl = described_class.new(capybara_page)
      dsl.find(:form, '.some-form')

      expect(dsl.element.form['class']).to eq('some-form')
    end

    it 'adds child elements from the block to the finder element' do
      dsl = described_class.new(capybara_page)
      dsl.find(:form, '.some-form') do
        find(:button, '.some-button')
      end

      expect(dsl.element.form.button['class']).to eq('some-button')
    end
  end

  describe '#all' do
    it 'adds a method to get all the elements matching the selector' do
      dsl = described_class.new(capybara_page)
      dsl.all(:buttons, 'button')

      expect(dsl.element.buttons).to have(2).elements
      expect(dsl.element.buttons).to be_all do |element|
        element.tag_name == 'button'
      end
    end

    it 'adds child elements from the block to each element returned' do
      dsl = described_class.new(capybara_page)
      dsl.all(:buttons, 'button') do
        find :img, 'img'
      end

      expect(dsl.element.buttons).to have(2).elements
      expect(dsl.element.buttons[0].img.tag_name).to eq('img')
    end
  end

  describe '#extend_element' do
    it 'can accept a module' do
      some_module = Module.new do
        def responds_to_this_method?
          true
        end
      end

      dsl = described_class.new(capybara_page)
      dsl.extend_element(some_module)

      expect(dsl.element.responds_to_this_method?).to be_true
    end

    it 'can accept a block' do
      dsl = described_class.new(capybara_page)
      dsl.extend_element do
        def responds_to_this_method?
          true
        end
      end

      expect(dsl.element.responds_to_this_method?).to be_true
    end

    it 'prefers the passed module with the block' do
      some_module = Module.new do
        def responds_to_module_method?
          true
        end

        def responds_to_block_method?
          false
        end
      end

      dsl = described_class.new(capybara_page)

      dsl.extend_element(some_module) do
        def responds_to_block_method?
          true
        end
      end

      expect(dsl.element.responds_to_module_method?).to be_true
      expect(dsl.element.responds_to_block_method?).to be_true
    end
  end
end
