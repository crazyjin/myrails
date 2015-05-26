#encoding uft-8
MyRails::Application.draw_routes do
  get "/blogs", "blogs_controller#index"
end
