
module Grafana

  # http://docs.grafana.org/http_api/annotations/
  #
  module Annotations

    # Find Annotations
    # http://docs.grafana.org/http_api/annotations/#find-annotations
    # GET /api/annotations?from=1506676478816&to=1507281278816&tags=tag1&tags=tag2&limit=100
    def find_annotation( params ); end

    # Create Annotation
    # http://docs.grafana.org/http_api/annotations/#create-annotation
    # POST /api/annotations
    def create_annotation( params ); end

    # Create Annotation in Graphite format
    # http://docs.grafana.org/http_api/annotations/#create-annotation-in-graphite-format
    # POST /api/annotations/graphite
    def create_annotation_graphite( params ); end

    # Update Annotation
    # http://docs.grafana.org/http_api/annotations/#update-annotation
    # PUT /api/annotations/:id
    def update_annotation( params ); end

    # Delete Annotation By Id
    # http://docs.grafana.org/http_api/annotations/#delete-annotation-by-id
    # DELETE /api/annotation/:id
    def delete_annotation( params ); end

    # Delete Annotation By RegionId
    # http://docs.grafana.org/http_api/annotations/#delete-annotation-by-regionid
    # DELETE /api/annotation/region/:id
    def delete_annotation_by_region( params ); end

  end

end
