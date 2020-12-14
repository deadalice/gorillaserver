require 'application_system_test_case'

class PackagesTest < ApplicationSystemTestCase
  setup { @package = packages(:one) }

  test 'visiting the index' do
    visit packages_url
    assert_selector 'h1', text: 'Packages'
  end

  test 'creating a Package' do
    visit packages_url
    click_on 'New Package'

    click_on 'Create Package'

    assert_text 'Package was successfully created'
    click_on 'Back'
  end

  test 'updating a Package' do
    visit packages_url
    click_on 'Edit', match: :first

    click_on 'Update Package'

    assert_text 'Package was successfully updated'
    click_on 'Back'
  end

  test 'destroying a Package' do
    visit packages_url
    page.accept_confirm { click_on 'Destroy', match: :first }

    assert_text 'Package was successfully destroyed'
  end
end
