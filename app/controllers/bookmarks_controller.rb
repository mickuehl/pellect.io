
require 'addressable/uri'

class BookmarksController < ApplicationController

  before_action :authenticate_user!
  before_action :set_bookmark, only: [:show, :edit, :update, :destroy]
  before_action :protect_bookmark!, only: [:show, :edit, :update, :destroy]

  # GET /bookmarks
  def index
    @bookmark = Bookmark.new
    @bookmarks = bookmark_stream_all
    @features = bookmark_stream_featured
        
    @bookmark_count_all = bookmark_count_all current_user
    @bookmark_count_unread = bookmark_count_unread current_user
    @bookmark_count_archived = bookmark_count_archived current_user
  end

  # GET /bookmarks/n
  def index_new
    @bookmark = Bookmark.new
    @bookmarks = bookmark_stream_new
    @features = bookmark_stream_featured
    
    @bookmark_count_all = bookmark_count_all current_user
    @bookmark_count_unread = bookmark_count_unread current_user
    @bookmark_count_archived = bookmark_count_archived current_user
    
    render :index
  end
  
  # GET /bookmarks/f
  def index_favorites
    @bookmark = Bookmark.new
    @bookmarks = bookmark_stream_favorites
    
    @bookmark_count_all = bookmark_count_all current_user
    @bookmark_count_unread = bookmark_count_unread current_user
    @bookmark_count_archived = bookmark_count_archived current_user
    
    render :index_noscroll
  end
  
  # GET /bookmarks/a
  def index_archive
    @bookmark = Bookmark.new
    @bookmarks = bookmark_stream_archived
    
    @bookmark_count_all = bookmark_count_all current_user
    @bookmark_count_unread = bookmark_count_unread current_user
    @bookmark_count_archived = bookmark_count_archived current_user
    
    render :index
  end
  
  # GET /bookmarks/o
  def index_oldest
    @bookmark = Bookmark.new
    @bookmarks = bookmark_stream_oldest
    
    @bookmark_count_all = bookmark_count_all current_user
    @bookmark_count_unread = bookmark_count_unread current_user
    @bookmark_count_archived = bookmark_count_archived current_user
    
    render :index
  end
  
  # GET /s/:site_id
  def by_site
    @bookmark = Bookmark.new
    @bookmarks = bookmark_stream_by_site params[:site_id]
    
    @bookmark_count_all = bookmark_count_all current_user
    @bookmark_count_unread = bookmark_count_unread current_user
    @bookmark_count_archived = bookmark_count_archived current_user
    
    render :index_noscroll
  end
  
  
  # GET /bookmarks/:id
  def show

  end

  # GET /bookmarks/new
  def new
    @bookmark = Bookmark.new
  end

  # GET /bookmarks/:id/edit
  def edit
    @bookmark_count_all = bookmark_count_all current_user
    @bookmark_count_unread = bookmark_count_unread current_user
    @bookmark_count_archived = bookmark_count_archived current_user
  end

  # POST /bookmarks
  def create
    Bookmark.create_or_retrieve bookmark_params
    @bookmarks = bookmark_stream_all
    @bookmark = Bookmark.new
    
    redirect_to bookmarks_url
  end

  # PATCH/PUT /bookmarks/:id
  def update

    if @bookmark.update(bookmark_params)
      @bookmarks = bookmark_stream_all
      @bookmark = Bookmark.new

      redirect_to bookmarks_url
    else
      render action: 'edit'
    end
  end

  # DELETE /bookmarks/:id
  def destroy
    @bookmark.destroy
    redirect_to bookmarks_url
  end

  # POST /a/:bookmark
  def archive
    bookmark = Bookmark.find(params[:bookmark])
    if bookmark
      bookmark.archived = true
      bookmark.save!
    end
    
    redirect_to(request.referrer || root_path) 
  end
  
  private

  # Use callbacks to share common setup or constraints between actions.
  def set_bookmark
    @bookmark = Bookmark.find(params[:id])
  end

  # Avoid that someone can access other user's bookmarks
  def protect_bookmark!
    # protect bookmarks from other users
    redirect_to bookmarks_url if @bookmark.user_id != current_user.id
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def bookmark_params
    if params[:bookmark]
      p = params[:bookmark].permit(:url,:description)
      p[:user_id] = current_user.id
      p[:url] = normalize_url params[:url] if params[:url]
    else
      p = {:url => normalize_url( params.require(:url)), :user_id => current_user.id }
    end

    puts p.to_s
    return p
  end

  # normalize the url
  def normalize_url(url)
    uri = Addressable::URI.parse url
    if uri.scheme == nil
      uri = Addressable::URI.parse ("http://" + url)
    end
    uri.normalize.to_s
  end
  
  #
  # helpers to select the right bookmarks
  #
  def bookmark_stream_all
    Bookmark.where(:user_id => current_user.id, :expired => false, :archived => false).paginate(:page => params[:page]).order('created_at DESC')
  end
  
  def bookmark_stream_oldest
    Bookmark.where(:user_id => current_user.id, :expired => false, :archived => false).paginate(:page => params[:page]).order('created_at ASC')
  end
  
  def bookmark_stream_archived
    Bookmark.where(:user_id => current_user.id, :expired => false, :archived => true).paginate(:page => params[:page]).order('created_at DESC')
  end
  
  def bookmark_stream_new
    Bookmark.where(:user_id => current_user.id, :view_count => 0, :expired => false, :archived => false).paginate(:page => params[:page]).order('created_at DESC')
  end
  
  def bookmark_stream_favorites
    Bookmark.where('user_id = ? and view_count > 0', current_user.id).order('view_count DESC').limit(30)
  end
  
  def bookmark_stream_by_site(site)
    Bookmark.where(:user_id => current_user.id, :site_id => site).order('created_at DESC')
  end
  
  # return a random selection of bookmarks; just a crude implementation, should be optimized with e.g. caching for some time
  def bookmark_stream_featured
    bookmarks = Bookmark.where(user_id: current_user.id, expired: false,  archived: false)
    
    features = []
    n = bookmarks.count -  1
    
    unless n < 16
      features << bookmarks[ Random.new.rand(0..n)]
      features << bookmarks[ Random.new.rand(0..n)]
      features << bookmarks[ Random.new.rand(0..n)]
    end
    
    features
  end
  
  def bookmark_count_all(current_user)
    Bookmark.where(user_id: current_user.id).count
  end
  
  def bookmark_count_unread(current_user)
    Bookmark.where(user_id: current_user.id, view_count: 0).count
  end
  
  def bookmark_count_archived(current_user)
    Bookmark.where(user_id: current_user.id, archived: true).count
  end
  
end
