class BlogsController < MyRails::Controller
  def index
    @hello = "Hello My Rails"
    render :index
  end
end
