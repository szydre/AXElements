class TestElementAttributes < TestElements

  def test_not_empty
    refute_empty AX::DOCK.attributes
  end

  def test_contains_proper_info
    assert AX::DOCK.attributes.include?(KAXRoleAttribute)
    assert AX::DOCK.attributes.include?(KAXTitleAttribute)
  end

end


class TestElementGetAttribute < TestElements

  def test_raises_arg_error_for_non_existent_attributes
    assert_raises ArgumentError do AX::DOCK.get_attribute('fakeattribute') end
    assert_raises ArgumentError do AX::DOCK.get_attribute(:fakeattribute) end
  end

  def test_matches_single_word_attribute
    assert_equal KAXApplicationRole, AX::DOCK.get_attribute( :role )
  end

  def test_matches_mutlti_word_attribute
    assert_equal 'application', AX::DOCK.get_attribute( :role_description )
  end

  def test_matches_acronym_attributes
    assert_instance_of NSURL, EL_DOCK_APP.get_attribute(:url)
  end

  def test_is_predicate_matches
    assert_instance_of_boolean EL_DOCK_APP.get_attribute(:application_running?)
  end

  def test_non_is_predicates_match
    assert_instance_of_boolean EL_DOCK_APP.get_attribute(:selected?)
  end

  def test_gets_exact_match_except_prefix
    # finds role when role and subrole exist
    assert_equal 'Dock', AX::DOCK.get_attribute(:title)

    # finds top_level_ui_element and shown_menu_ui_element exists
    top_level  = EL_DOCK_APP.get_attribute(:top_level_ui_element)
    shown_menu = EL_DOCK_APP.get_attribute(:shown_menu_ui_element)
    refute_equal top_level, shown_menu
    assert_instance_of AX::List, top_level
    assert_nil shown_menu
  end

end


class TestElementDescription < TestElements

  def test_raise_error_if_object_has_no_description
    assert_raises ArgumentError do AX::DOCK.description end
  end

  def test_gets_description_if_object_has_a_description
    element = AX.element_at_position(
      CGPoint.new(NSScreen.mainScreen.frame.size.width - 10, 10)
                                     )
    assert_equal 'spotlight menu', element.description
  end

end


class TestElementPID < TestElements

  def test_actually_works
    assert_instance_of Fixnum, EL_DOCK_APP.pid
    refute EL_DOCK_APP.pid == 0
  end

end


class TestElementAttributeWritable < TestElements

  def test_raises_error_for_non_existant_attributes
    assert_raises ArgumentError do
      AX::DOCK.attribute_writable?(:fake_attribute)
    end
  end

  def test_true_for_writable_attributes
    assert EL_DOCK_APP.attribute_writable? :selected
  end

  def test_false_for_non_writable_attributes
    refute AX::DOCK.attribute_writable? :title
  end

end


class TestElementSetAttribute < TestElements

  def test_set_a_text_fields_value
    spotlight_text_field do |field|
      new_value = "#{Time.now}"
      item = AX::Element.new(field)
      item.set_attribute( :value, new_value )
      assert_equal new_value, attribute_for( field, KAXValueAttribute )
    end
  end

end


# @todo implement missing test cases
class TestElementParamAttributes < TestElements

  def test_empty_for_dock
    assert_empty AX::DOCK.param_attributes
  end

  # def test_not_empty_for_something
  # end
  # def test_contains_proper_info
  # end
  # @todo some other tests copied from testing #get_attributes

end


# @todo I'll get to this when I need to get to parameterized attributes
class TestElementGetParamAttribute < TestElements

#   def test_returns_nil_for_non_existent_attributes
#   end
#   def test_fetches_attribute
#   end

end


class TestElementActions < TestElements

  def test_empty_for_dock
    assert_empty AX::DOCK.actions
  end

  def test_not_empty_for_dock_item
    refute_empty EL_DOCK_APP.actions
  end

  def test_contains_proper_info
    assert EL_DOCK_APP.actions.include?(KAXPressAction)
    assert EL_DOCK_APP.actions.include?(KAXShowMenuAction)
  end

end


class TestElementPerformAction < TestElements

  def test_returns_boolean
    assert_equal true, EL_DOCK_APP.perform_action(:show_menu)
  end

  def test_does_name_translation
    before_kids = EL_DOCK_APP.attribute(KAXChildrenAttribute).size
    EL_DOCK_APP.perform_action(:show_menu)
    after_kids = EL_DOCK_APP.attribute(KAXChildrenAttribute).size
    refute_equal after_kids, before_kids
  end

  def test_raise_error_for_non_existant_action
    assert_raises ArgumentError do
      EL_DOCK_APP.perform_action(:fake_action)
    end
  end

end


class TestElementSearch < TestElements

  def test_plural_calls_find_all
    assert_instance_of Array, AX::DOCK.search(:application_dock_items)
  end

  def test_singular_calls_find
    assert_kind_of AX::Element, AX::DOCK.search(:list)
  end

  def test_works_with_no_filters
    assert_equal 'AXList', AX::DOCK.search(:list).attribute(KAXRoleAttribute)
  end

  # @note this test is kind of fragile
  def test_forwards_all_filters
    assert_raises ArgumentError do
      AX::DOCK.search(:application_dock_item, clearly_fake_attribute: true)
    end
  end

end


class TestElementMethodMissing < TestElements

  def test_finds_attribute
    assert_equal 'Dock', AX::DOCK.title
  end

  def test_does_search_if_has_kids
    assert_instance_of AX::ApplicationDockItem, AX::DOCK.application_dock_item
  end

  def test_does_not_search_if_no_kids
    assert_raises NoMethodError do
      AX::SYSTEM.list
    end
  end

end


class TestElementNotifications < TestElements

  def test_wait_for_window_created
    class << AX
      alias_method :old_register_for_notif, :register_for_notif
      def register_for_notif ref, notif, &block
        [
         CFGetTypeID(ref) == AXUIElementGetTypeID(),
         notif == KAXWindowCreatedNotification,
         (block.call if block)
        ]
      end
    end
    ret = AX::DOCK.on_notification(:window_created)
    ret.concat AX::DOCK.on_notification(:window_created) { 'test' }
    assert_equal [true, true, nil, true, true, 'test'], ret
  ensure
    class << AX
      alias_method :register_for_notif, :old_register_for_notif
    end
  end

  def test_argument_error_for_non_existent_constant
    assert_raises ArgumentError do
      AX::DOCK.on_notification(:made_up_notification)
    end
  end

end


class TestElementInspect < TestElements

  def test_includes_attributes
    output = AX::DOCK.inspect
    assert_match /@attributes=/, output
    assert_match /Title/, output
    refute_match /AXTitle/, output
  end

end


# @todo Test this once the recursive feature starts working
# class TestElementPrettyPrint < TestElements
#   def test_hash_of_attributes
#     # is a hash
#     # has attributes as the keys
#     # has the correct values
#   end
#   # def test_is_recursive
#   # end
# end


class TestElementRespondTo < TestElements

  def test_works_on_attributes
    assert AX::DOCK.respond_to?(:title)
  end

  def test_does_not_work_with_search_names
    refute AX::DOCK.respond_to?(:list)
  end

  def test_works_for_regular_methods
    assert AX::DOCK.respond_to?(:attributes)
  end

  def test_returns_false_for_non_existant_methods
    refute AX::DOCK.respond_to?(:crazy_thing_that_cant_work)
  end

end


# @todo Test this once it is implemented
# class TestElementMethods < TestElements
# end


class TestElementEquivalence < TestElements

  def dock
    Accessibility.application_for_bundle_identifier('com.apple.dock', 1.0)
  end

  def list
    AX::DOCK.attribute(KAXChildrenAttribute).first
  end

  def test_dock_app_is_equal_to_dock_app
    assert AX::DOCK == dock
    assert AX::DOCK.eql? dock
    assert AX::DOCK.equal? dock
    refute AX::DOCK != dock
  end

  def test_dock_list_is_equal_to_dock_list
    assert list == list
    assert list.eql? list
    assert list.equal? list
    refute list != list
  end

  def test_dock_app_not_equal_to_finder_app
    refute AX::DOCK == AX::FINDER
    refute AX::DOCK.eql? AX::FINDER
    refute AX::DOCK.equal? AX::FINDER
    assert AX::DOCK != AX::FINDER
  end

  def test_dock_app_is_not_equal_to_dock_list
    refute AX::DOCK == list
    refute AX::DOCK.eql? list
    refute AX::DOCK.equal? list
    assert AX::DOCK != list
  end

end
