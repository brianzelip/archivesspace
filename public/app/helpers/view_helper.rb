module ViewHelper
  # TODO: figure out a clever way to DRY these helpers up.

  # returns repo URL via slug if defined, via ID it not.
  def repository_base_url(result)
    url = if result['slug'] && AppConfig[:use_human_readable_urls]
            'repositories/' + result['slug']
          else
            result['uri']
          end

    url
  end

  def resource_base_url(result)
    url = if result.json['slug'] && AppConfig[:use_human_readable_urls]
            # Generate URLs with repo slugs if turned on
            if AppConfig[:repo_name_in_slugs]
              if result.resolved_repository['slug']
                "repositories/#{result.resolved_repository['slug']}/resources/" + result.json['slug']

              # just use ids if repo has no slug
              else
                result['uri']
                    end

            # otherwise, generate URL without repo slug
            else
              'resources/' + result.json['slug']
                  end

          # object has no slug
          else
            result['uri']
          end

    url
  end

  def digital_object_base_url(result)
    url = if result.json['slug'] && AppConfig[:use_human_readable_urls]
            if AppConfig[:repo_name_in_slugs]
              if result.resolved_repository['slug']
                "repositories/#{result.resolved_repository['slug']}/digital_objects/" + result.json['slug']
              else
                result['uri']
                    end

            # otherwise, generate URL without repo slug
            else
              'digital_objects/' + result.json['slug']
                  end
          else
            result['uri']
          end

    url
  end

  def accession_base_url(result)
    url = if result.json['slug'] && AppConfig[:use_human_readable_urls]
            if AppConfig[:repo_name_in_slugs]
              if result.resolved_repository['slug']
                "repositories/#{result.resolved_repository['slug']}/accessions/" + result.json['slug']
              else
                result['uri']
                    end

            # otherwise, generate URL without repo slug
            else
              'accessions/' + result.json['slug']
                  end
          else
            result['uri']
          end

    url
  end

  def subject_base_url(result)
    url = if result.json['slug'] && AppConfig[:use_human_readable_urls]
            'subjects/' + result.json['slug']
          else
            result['uri']
          end

    url
  end

  def classification_base_url(result)
    url = if result.json['slug'] && AppConfig[:use_human_readable_urls]
            if AppConfig[:repo_name_in_slugs]
              if result.resolved_repository['slug']
                "repositories/#{result.resolved_repository['slug']}/classifications/" + result.json['slug']
              else
                result['uri']
                    end

            # otherwise, generate URL without repo slug
            else
              'classifications/' + result.json['slug']
                  end
          else
            result['uri']
          end

    url
  end

  def agent_base_url(result)
    url = if result.json['slug'] && AppConfig[:use_human_readable_urls]
            'agents/' + result.json['slug']
          else
            result['uri']
          end

    url
  end

  def archival_object_base_url(result)
    url = if result.json['slug'] && AppConfig[:use_human_readable_urls]
            if AppConfig[:repo_name_in_slugs]
              if result.resolved_repository['slug']
                "repositories/#{result.resolved_repository['slug']}/archival_objects/" + result.json['slug']
              else
                result['uri']
                    end

            # otherwise, generate URL without repo slug
            else
              'archival_objects/' + result.json['slug']
                  end
          else
            result['uri']
          end

    url
  end
end
