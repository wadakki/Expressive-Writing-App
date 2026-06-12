require "test_helper"

class StaticPagesControllerTest < ActionDispatch::IntegrationTest
  test "shows the terms page" do
    get terms_url

    assert_response :success
    assert_select "h1", "利用規約"
  end

  test "shows the privacy page" do
    get privacy_url

    assert_response :success
    assert_select "h1", "プライバシーポリシー"
  end

  test "shows the contact page" do
    get contact_url

    assert_response :success
    assert_select "h1", "お問い合わせ"
  end
end
